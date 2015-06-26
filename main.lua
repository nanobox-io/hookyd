-- -*- mode: lua; tab-width: 2; indent-tabs-mode: 1; st-rulers: [70] -*-
-- vim: ts=4 sw=4 ft=lua noet
---------------------------------------------------------------------
-- @author Daniel Barney <daniel@pagodabox.com>
-- @copyright 2015, Pagoda Box, Inc.
-- @doc
--
-- @end
-- Created :   3 Sept 2014 by Daniel Barney <daniel@pagodabox.com>
---------------------------------------------------------------------

local parse_opts = require('parse-opts')
local fs = require('coro-fs')
local sleep = require('coro-sleep')
local json = require('json')
local uv = require('uv')
local weblit = require('weblit-app')

local job = require('./lib/job')
local function log(...)
	print(os.date("%x %X"),...)
end

coroutine.wrap(function()

	local default_opts =
		{config = '/opt/local/etc/hookyd/hookyd.conf'}

	parse_opts(default_opts,args)

	local data = assert(fs.readFile(default_opts.config))
	local config = json.parse(data)

	assert(config.hooky, '"hooky" parameter is missing in config file')
	assert(config.hook_dir, '"hook_dir" parameter is missing in config file')
	assert(config.port, '"port" parameter is missing in config file')

	local function respond(res,body)
		res.code = 200
			res.body = body
			res.headers[#res.headers +1] = 
				{'content-type','application/json'}
	end
	local last_job

	weblit
		.use(require('weblit-auto-headers'))
		.use(function(req,res,go)
			log(req.path)
			go()
		end)

		.route({path = '/ping'},function(req,res)
			respond(res, '{"ping":"pong"}')
		end)

		.route({path = '/pkill'},function(req,res)
			local code, body
			repeat 
				code, body = job.attach('pkill', '-u', '1001')
				sleep(1000)
				-- code == 0 means that there still are processes left running
			until code ~= 0
			local data = json.stringify(
				{exit = code
				,out = body})
			respond(res, data)
		end)

		.route({path = '/hooks/:hook_id'},function(req,res)
			local hook = table.concat(
				{config.hook_dir
				,'/'
				,req.params.hook_id
				,'.rb'})

			if fs.stat(hook) == nil then
				-- returns 404 by default
				return
			end

			if last_job and last_job.hook == req.params.hook_id then
				-- send off the results of the last job run
				local data = json.stringify(
					{exit = last_job.code
					,out = last_job.body})
				respond(res, data)

				last_job = nil
			else
				local hook_id = req.params.hook_id
				-- create or attach to a job
				local body, code = job.attach(config.hooky, hook_id,
					req.body)

				if body:match('ENOMEM') or body:match('out of memory') then
					code = 3
				end

				last_job = 
					{hook = hook_id
					,code = code
					,body = body}

				local data = json.stringify(
					{exit = code
					,out = body})
				respond(res, data)

			end
		end)
		.bind({port = config.port, ip = config.host})
		.start()

end)()

uv.run()