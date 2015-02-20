(*
 * Copyright (c) 2012-2014 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

module CD = Cohttp_lwt_unix_debug
let () = Sys.(set_signal sigpipe Signal_ignore)
module Lwt_io = Uwt_io

type 'a t = 'a Lwt.t
let (>>=) = Lwt.bind
let return = Lwt.return

type ic = Lwt_io.input_channel
type oc = Lwt_io.output_channel
type conn = Conduit_lwt_unix.flow

let iter fn x = Lwt_list.iter_s fn x

let read_line ic =
  if !CD.debug_active then
    (match_lwt Lwt_io.read_line_opt ic with
     | None -> CD.debug_print "<<< EOF\n"; Lwt.return_none
     | Some l as x -> CD.debug_print "<<< %s\n" l; Lwt.return x)
  else
    Lwt_io.read_line_opt ic

let read ic count =
 if !CD.debug_active then
   (lwt buf =
       try_lwt Lwt_io.read ~count ic
       with End_of_file -> return "" in
     CD.debug_print "<<<[%d] %s" count buf;
     return buf)
 else
   (try_lwt Lwt_io.read ~count ic
     with End_of_file -> return "")

let read_exactly ic buf off len =
  if !CD.debug_active then
   (lwt rd =
        try_lwt Lwt_io.read_into_exactly ic buf off len >>= fun () ->  return true
        with End_of_file -> return false in
      (match rd with
      |true -> CD.debug_print "<<< %S" (String.sub buf off len)
      |false -> CD.debug_print "<<< <EOF>\n");
      return rd)
  else
    (try_lwt Lwt_io.read_into_exactly ic buf off len >>= fun () ->  return true
      with End_of_file -> return false)

let read_exactly ic len =
  let buf = Bytes.create len in
  read_exactly ic buf 0 len >>= function
    | true -> return (Some buf)
    | false -> Lwt.return_none

let write oc buf =
  if !CD.debug_active then
    (CD.debug_print ">>> %s" buf; Lwt_io.write oc buf)
  else
    (Lwt_io.write oc buf)

let write_line oc buf =
  if !CD.debug_active then
    (CD.debug_print ">>> %s\n" buf; Lwt_io.write_line oc buf)
  else
    (Lwt_io.write_line oc buf)

let flush oc =
  Lwt_io.flush oc
