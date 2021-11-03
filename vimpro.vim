
function! IndentThisFile ()
	execute "arg % | argdo normal gg=G:wq\<CR>"
endfunction

function! IndentAllFiles ()
	execute "arg **/*.[ch] | argdo normal gg=G:w\<CR>"
endfunction

function! ReplaceStringInThisFile (oldr, newr)
	execute "%s/".a:oldr."/".a:newr."/gce | update"
endfunction

function! ReplaceStringInAllFiles (oldr, newr)
	execute "arg **/*.[ch] | argdo %s/".a:oldr."/".a:newr."/gce | update"
endfunction

function! ConvertToSyslog (PrintFn, ConvType)
	let l:logl = ['EMERG', 'ALERT', 'CRIT', 'ERR', 'WARNING', 'NOTICE', 'INFO', 'DEBUG']
	for level in l:logl
		echom " "
		echom "******** vimpro: Crawl and replace for LOG_".level."? "
		let l:yes = getchar ()
		if (nr2char (l:yes) == "y")
			if (a:ConvType == "all")
				call ReplaceStringInAllFiles (a:PrintFn."\.\\\{\-\}(", "syslog (LOG_".level.", ")
			else
				call ReplaceStringInThisFile (a:PrintFn."\.\\\{\-\}(", "syslog (LOG_".level.", ")
			endif
			echom "******** vimpro: Done with LOG_".level
			echom " "
		endif
	endfor
endfunction

