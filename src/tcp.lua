--- Transmission Control Protocol (TCP) packet dissector.
-- This module is based on code adapted from nmap's nselib. See http://nmap.org/.
-- @module tcp
local bstr = require ("bstr")
local bit = require ("bit32")
local tcp = {}

local function tcp_parseopts (buff, offset, length)
	local options = {}
	local op = 1
	local opt_ptr = 0

	while opt_ptr < length do
		local t, l, d
		options[op] = {}

		t = bstr.u8(buff, offset + opt_ptr)
		options[op].type = t

		if t==0 or t==1 then
			l = 1
			d = nil
		else
			l = bstr.u8(buff, offset + opt_ptr + 1)

			if l > 2 then
				d = raw(buff, offset + opt_ptr + 2, l-2)
			end
		end

		options[op].len  = l
		options[op].data = d
		opt_ptr = opt_ptr + l
		op = op + 1
	end

	return options
end

--- Create a new object.
-- @tparam string packet pass packet data as an opaque string
-- @treturn table New tcp table.
function tcp.new (packet)
	if type (packet) ~= "string" then
		error ("parameter 'packet' is not a string", 2)
	end

	local tcp_pkt = setmetatable ({}, { __index = tcp })

	tcp_pkt.buff = packet

	return tcp_pkt
end

function tcp:parse ()
	if string.len (self.buff) < 20 then
		self.errmsg = "incomplete TCP header data"
		return false
	end

	self.tcp_sport = bstr.u16 (self.buff, 0)
	self.tcp_dport = bstr.u16 (self.buff, 2)
	self.tcp_seq = bstr.u32 (self.buff, 4)
	self.tcp_ack = bstr.u32 (self.buff, 8)
	self.tcp_hl = bit.rshift (bit.band(bstr.u8(self.buff, 12), 0xF0), 4) * 4
	self.tcp_x2 = bit.band (bstr.u8 (self.buff, 12), 0x0F)
	self.tcp_flags = bstr.u8 (self.buff, 13)

	self.tcp_th = {}
	self.tcp_th["fin"] = bit.band(self.tcp_flags, 0x01) ~= 0 -- true/false
	self.tcp_th["syn"] = bit.band(self.tcp_flags, 0x02) ~= 0
	self.tcp_th["rst"] = bit.band(self.tcp_flags, 0x04) ~= 0
	self.tcp_th["push"] = bit.band(self.tcp_flags, 0x08) ~= 0
	self.tcp_th["ack"] = bit.band(self.tcp_flags, 0x10) ~= 0
	self.tcp_th["urg"] = bit.band(self.tcp_flags, 0x20) ~= 0
	self.tcp_th["ece"] = bit.band(self.tcp_flags, 0x40) ~= 0
	self.tcp_th["cwr"] = bit.band(self.tcp_flags, 0x80) ~= 0

	self.tcp_win = bstr.u16 (self.buff, 14)
	self.tcp_sum = bstr.u16 (self.buff, 16)
	self.tcp_urgp = bstr.u16 (self.buff, 18)
	self.tcp_opt_offset = 20
	self.tcp_options = tcp_parseopts (self.buff, self.tcp_opt_offset, (self.tcp_hl - 20))
	--self.tcp_data_len = string.len (self.buff) - self.tcp_hl

	return true
end

function tcp:get_data ()
	return string.sub (self.buff, self.tcp_hl + 1, -1)
end

function tcp:get_datalen ()
	return string.len (self.buff) - self.tcp_hl
end

--- Change or set new packet data.
-- @tparam string packet pass packet data as an opaque string
function tcp:set_packet (packet)
	self.buff = packet
end

--- TODO
function tcp:get_srcport ()
	return self.tcp_sport
end

--- TODO
function tcp:get_dstport ()
	return self.tcp_dport
end

function tcp:get_seqnum ()
	return self.tcp_seq
end

function tcp:get_acknum ()
	return self.tcp_ack
end

function tcp:get_hdrlen ()
	return self.tcp_hl
end

function tcp:get_flags ()
	return self.tcp_th
end

function tcp:get_rawflags ()
	return self.tcp_flags
end

function tcp:isset_fin ()
	return self.tcp_th["fin"]
end

function tcp:isset_syn ()
	return self.tcp_th["syn"]
end

function tcp:isset_rst ()
	return self.tcp_th["rst"]
end

function tcp:isset_push ()
	return self.tcp_th["push"]
end

function tcp:isset_ack ()
	return self.tcp_th["ack"]
end

function tcp:isset_urg ()
	return self.tcp_th["urg"]
end

function tcp:isset_echo ()
	return self.tcp_th["echo"]
end

function tcp:isset_cwr ()
	return self.tcp_th["cwr"]
end

function tcp:get_winsize ()
	return self.tcp_win
end

function tcp:get_checksum ()
	return self.tcp_sum
end

function tcp:get_urgpointer ()
	return self.tcp_urgp
end

return tcp

