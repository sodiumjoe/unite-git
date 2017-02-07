" Usage: Unite gstatus	"unite git status

let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#git_status#define()
  return s:source
endfunction

let s:source = {
      \ 'name': 'git_status',
      \ 'description': 'candidates from git status',
      \ 'syntax' : 'uniteSource__uniteGitStatus',
      \ 'default_kind': 'file',
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
  return {
        \	'source': 'git_status',
        \	'kind': 'file',
        \ 'word': word,
        \	'action__path' : path
        \	}
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
