#!/usr/bin/env luvit
-- -*- mode: lua; tab-width: 2; indent-tabs-mode: 1; st-rulers: [70] -*-
-- vim: ts=4 sw=4 ft=lua noet
---------------------------------------------------------------------
-- @author Daniel Barney <daniel@pagodabox.com>
-- @copyright 2014, Pagoda Box, Inc.
-- @doc
--
-- @end
-- Created :   3 Sept 2014 by Daniel Barney <daniel@pagodabox.com>
---------------------------------------------------------------------

local JSON  = require('json')
local table = require("table")
local Lever = require("./lever")
local Job   = require("./job")

local lever = Lever:new()

-- ping pong endpoint
function ping(req,res)
  res:writeHead(200,{})
  res:finish("{\"ping\":\"pong\"}")
end

-- run or attach to a running hook
function run_hook(req,res)
  local chunks = {}

  -- eat up the entire body
  req:on('data', function (chunk, len)
  	if chunks then
		  chunks[#chunks + 1] = chunk
		end
  end)

  -- on error clear out all chunks stored
  req:once('error',function ()
    chunks = nil
  end)

  -- request has completely been read in
  req:once('end', function ()
  	if chunks then

	    -- combine all chunks into the payload
	    local payload = table.concat(chunks, "")
	    chunks = nil;

	    -- attach to a job
	    Job.attach(req.env.hook_id,payload,function(code,body)

	      -- send response
	      local response = JSON.stringify({code = code, body = body})
	      res:writeHead(200, {
	        ["Content-Type"] = "application/json",
	        ["Content-Length"] = #response
	      })
	      res:finish(response)
	    end)
	  end
  end)
end


-- routing endpoints
lever:all("/ping",ping)
lever:post("/hooks/?hook_id",run_hook)
lever:put("/hooks/?hook_id",run_hook)

-- start server
lever:listen(8080)

process:on('error', function(err)
	p("global error: ",{err=err})
end)