" Usage: Unite gstatus "unite git status

let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#git_status#define()
  return s:source
endfunction

function! s:unite_git_stage(candidate)
  let path = a:candidate['action__path']
  let is_staged = a:candidate['is_staged']
  let command = is_staged ? '!git reset ' : '!git add '

  execute command . path
endfunction

function! s:unite_git_diff(candidate)
  let path = a:candidate['action__path']
  execute 'e ' . path
  execute 'Gdiff'
endfunction

let s:unite_git_stage_action = {
      \ 'func': function('s:unite_git_stage'),
      \ 'description': 'Stages or resets a file.',
      \ 'is_quit': 0,
      \ 'is_selectable': 0,
      \ 'is_invalidate_cache': 1
      \ }

let s:unite_git_diff_action = {
      \ 'func': function('s:unite_git_diff'),
      \ 'description': ':Gdiff (depends on vim-fugitive)',
      \ 'is_selectable': 0
      \ }

let s:unite_git_action_table = {
      \ 'stage': s:unite_git_stage_action,
      \ }

if exists('g:loaded_fugitive')
  let s:unite_git_action_table['diff'] = s:unite_git_diff_action
endif


let s:source = {
      \ 'name': 'git_status',
      \ 'description': 'candidates from git status',
      \ 'syntax' : 'uniteSource__uniteGitStatus',
      \ 'default_kind': 'file',
      \ 'action_table': { '*': s:unite_git_action_table },
      \ 'hooks': {}
      \ }

let s:status_symbol_map = {
      \ ' ': ' ',
      \ 'M': 'M',
      \ 'A': '+',
      \ 'D': '-',
      \ 'R': '→',
      \ 'C': '📋',
      \ 'U': 'U',
      \ '?': '?'
      \ }

function! s:git_status_to_unite(val)
  let index_status = a:val[0]
  let work_tree_status = a:val[1]
  let raw_rest = strpart(a:val, 3)
  let rest = substitute(raw_rest, '"', '', 'g')
  let move_dest = matchstr(rest, '-> \zs.\+\ze')
  let path = empty(move_dest) ? rest : move_dest
  let index_status_symbol = s:status_symbol_map[index_status]
  let work_tree_status_symbol = s:status_symbol_map[work_tree_status]
  let word = index_status_symbol . work_tree_status_symbol . ' ' . rest
  let is_staged = index_status == 'M'
  return {
        \ 'source': 'git_status',
        \ 'kind': 'file',
        \ 'word': word,
        \ 'action__path' : path,
        \ 'is_volatile': 1,
        \ 'is_staged': is_staged
        \ }
endfunction

function! s:source.gather_candidates(args, context)
  let raw = system('git status --porcelain -uall')
  let lines = split(raw, '\n')
  return map(lines, "s:git_status_to_unite(v:val)")
endfunction

function! s:source.hooks.on_syntax(args, context)

  if !hlexists('UniteGitStatusIndexSymbol')
    highlight link UniteGitStatusIndexSymbol Statement
  endif

  if !hlexists('UniteGitStatusWorkingTreeSymbol')
    highlight link UniteGitStatusWorkingTreeSymbol Error
  endif

  syntax match UniteGitStatusIndexSymbol /^\s\s\s../
        \ containedin=uniteSource__uniteGitStatus

  syntax match UniteGitStatusWorkingTreeSymbol /^\s\s\s.\zs./
        \ contained containedin=UniteGitStatusIndexSymbol

endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
