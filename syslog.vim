
nmap <c-l><c-l> :call Rvsyslog0()<cr>

function! Rvsyslog0()
	arg **/*.[ch] | argdo %s/printf(/wlc_log (LOG_EMERG, /gce | update
	arg **/*.[ch] | argdo %s/printf(/wlc_log (LOG_ALERT, /gce | update
	arg **/*.[ch] | argdo %s/printf(/wlc_log (LOG_CRIT, /gce | update
	arg **/*.[ch] | argdo %s/printf(/wlc_log (LOG_ERR, /gce | update
	arg **/*.[ch] | argdo %s/printf(/wlc_log (LOG_WARNING, /gce | update
	arg **/*.[ch] | argdo %s/printf(/wlc_log (LOG_NOTICE, /gce | update
	arg **/*.[ch] | argdo %s/printf(/wlc_log (LOG_INFO, /gce | update
	arg **/*.[ch] | argdo %s/printf(/wlc_log (LOG_DEBUG, /gce | update
endfunction

