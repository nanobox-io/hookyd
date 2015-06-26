-- -*- mode: lua; tab-width: 2; indent-tabs-mode: 1; st-rulers: [70] -*-
-- vim: ts=4 sw=4 ft=lua noet
---------------------------------------------------------------------
-- @author Daniel Barney <daniel@pagodabox.com>
-- @copyright 2015, Pagoda Box, Inc.
-- @doc
--
-- @end
-- Created :   26 June 2015 by Daniel Barney <daniel@pagodabox.com>
---------------------------------------------------------------------

return 
  {name = "pagodabox/hookyd"
  ,version = "0.0.1"
  ,author =
    {name = "Daniel Barney"
    ,email = "daniel@pagodabox.com"}
  ,tags = 
    {"hooks"
    ,"remote"
    ,"management"}
  ,license = "MIT"
  ,homepage = "https://github.com/pagodabox/hookyd"
  ,description = 
  	"A remote management plane for executing machine configuration hooks"
  ,dependencies = 
    {"luvit/require@1.2.0"
    ,"luvit/pretty-print@1.0.2-1"
    ,"creationix/weblit-app@0.2.6-1"
    ,"creationix/weblit-auto-headers@0.1.2-1"
    ,"creationix/coro-fs@1.3.0"
    ,"creationix/coro-split@0.1.1"
    ,"creationix/coro-spawn@0.2.1"
    ,"pagodabox/coro-sleep@0.1.0"
    ,"pagodabox/logger@0.1.0"
    ,"pagodabox/parse-opts@0.1.0"
    ,"luvit/json@2.5.0"}
  ,files =
    {"**.lua"
    ,"!tests"}}