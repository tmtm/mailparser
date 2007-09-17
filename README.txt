= MailParser =

メールメッセージを解析する。

== 作者 ==

とみたまさひろ <tommy@tmtm.org>

== ライセンス ==

Ruby ライセンス http://www.ruby-lang.org/ja/LICENSE.txt と同等。

== 機能 ==

 * メールファイルをパースした結果を返す。
 * メール構造による例外は発生しない(例外を発生させることも可能)。
   不正な構造のメッセージがあった場合は適当に処理する。

 * 0.4 でイチから作りなおしたので、0.3 とは互換がない。
   require "mailparser/obsolete" すれば 0.3 と同じ機能が使用可能。

== ダウンロード ==

 * http://tmtm.org/downloads/ruby/mailparser/

== インストール ==

インストールには racc が必要。

{{{
$ make
$ make test
# make install
}}}

== 使用例 ==

{{{
require "mailparser"
File.open("/tmp/hoge.eml") do |f|
  m = MailParser::Message.new(f, :decode_mime_header=>true)
  m.from                # => From ヘッダ (MailParser::RFC2822::Mailbox)
  m.to                  # => To ヘッダ (MailParser::RFC2822::Mailbox の配列)
  m.subject             # => Subject 文字列 (String)
  m.body                # => 本文文字列 (String)
  m.charset             # => 本文文字コード (String)
  m.part                # => 添付ファイル (MailParser::Message の配列)
  m.part[0].filename    # => １つめの添付ファイルのファイル名 (String)
  m.part[0].body        # => １つめの添付ファイルの本文 (String)
end
}}}

== MailParser::Message ==

=== self.new(io, [opt]) ===
 
io から MailParser::Message オブジェクトを生成する。

io には IO または StringIO オブジェクトを指定する。実際には１行毎の文
字列を返す gets イテレータを持ち、処理した位置を覚えていて次回実
行時に続きから実行できるオブジェクトであれば何でも良い。
String オブジェクトも指定可能。内部で StringIO が生成されて使用される。

opt は Hash オブジェクトで次の値を指定できる。

 :skip_body => true
   本文をスキップする。デフォルトは false。

 :text_body_only => true
   text/* type 以外の本文をスキップする。デフォルトは false。

 :extract_message_type => true
   message/* type を展開する。デフォルトは false。

 :decode_mime_header => true
   MIMEヘッダをデコードする。デフォルトは false。

 :decode_mime_filename => true
   MIME エンコードされたファイル名をデコードする。デフォルトは false。
   
 :output_charset => charsetname
   出力文字コード。デフォルトは nil で無変換。

 :strict => true
   RFC違反時に ParseError 例外を発生する。デフォルトは false。

 :keep_raw => true
   生メッセージ文字列を保持する。デフォルトは false。

=== from ===

From ヘッダのパース結果の最初のアドレスを MailParser::Mailbox オブジェクトで返す。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS))
From: TOMITA Masahiro <tommy@tmtm.org>
EOS
m.from.display_name   # => "TOMITA Masahiro"
m.from.addr_spec.to_s # => "tommy@tmtm.org"
}}}

=== to ===

To ヘッダのパース結果を MailParser::Mailbox オブジェクトの配列で返す。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS))
To: TOMITA Masahiro <tommy@tmtm.org>, foo@example.com
EOS
m.to[0].to_s   # => "TOMITA Masahiro <tommy@tmt.morg>"
m.to[1].to_s   # => "<foo@example.com>"
}}}

=== cc ===

Cc ヘッダのパース結果を MailParser::Mailbox オブジェクトの配列で返す。

=== subject ===

Subject ヘッダの値を文字列で返す。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS), :decode_mime_header=>true, :output_charset=>"utf-8")
Subject: =?iso-2022-jp?b?GyRCJEgkXyQ/JEckORsoQg==?=
EOS
m.subject    # => "とみたです"
}}}

=== type ===

Content-Type ヘッダのタイプを小文字の文字列で返す。
Content-Type がない場合は "text" を返す。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS), :decode_mime_header=>true, :output_charset=>"utf-8")
Content-Type: Text/Plain; charset=ISO-2022-JP
EOS
m.type     # => "text"
m.subtype  # => "plain"
m.charset  # => "iso-2022-jp"
}}}

=== subtype ===

Content-Type ヘッダのサブタイプを小文字の文字列で返す。
Content-Type がない場合またはサブタイプがない場合は "plain" を返す。

=== charset ===

Content-Type ヘッダの charset 属性を小文字の文字列で返す。
Content-Type がない場合または charset がない場合は nil を返す。

=== multipart? ===

マルチパートメッセージの場合 true を返す。

=== filename ===

ファイル名を返す。
ファイル名は、Content-Disposition ヘッダの filename 属性または Content-Type ヘッダの name 属性から取得する(Content-Disposition ヘッダが優先)。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS))
Content-Disposition: attachment; filename="hogehoge.txt"
EOS
m.filename  # => "hogehoge.txt"
}}}

{{{
m = MailParser::Message.new(StringIO.new(<<EOS))
Content-Disposition: attachment; filename*=utf-8''%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E5%90%8D.txt
EOS
m.filename # => "ファイル名.txt"
}}}

RFC的には正しくない(でも一般に使われている)ダブルクォートで括られてMIMEエンコードされた文字列を MIMEデコードしたい場合は、:decode_mime_filename=>true を指定する必要がある。

{{{
m = MailParser::Message.new(StringIO.new(<<EOS), :decode_mime_filename=>true)
Content-Disposition: attachment; filename="=?utf-8?b?44OV44Kh44Kk44Or5ZCNLnR4dA==?="
EOS
m.filename # => "ファイル名"
}}}

=== header ===

ヘッダを表す MailParser::Header オブジェクトを返す。
MailParser::Header はハッシュのように使用できる。
キーは小文字のヘッダ名文字列で、値はヘッダオブジェクトの配列(複数存在する場合があるので配列)。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS))
From: TOMITA Masahiro <tommy@tmtm.org>
To: foo@example.com
Subject: test subject
EOS
m.header["from"][0]      # => MailParser::Mailbox の配列
m.header["to"][0]        # => MailParser::Mailbox の配列
m.header["subject"][0]   # => String
}}}

ヘッダとパース結果のクラスの対応は次の通り。

|| Date                      || MailParser::DateTime
|| From                      || MailParser::Mailbox の配列
|| Sender                    || MailParser::Mailbox
|| Reply-To                  || MailParser::Mailbox または MailParser::Group の配列
|| To                        || MailParser::Mailbox または MailParser::Group の配列
|| Cc                        || MailParser::Mailbox または MailParser::Group の配列
|| Bcc                       || MailParser::Mailbox または MailParser::Group の配列
|| Message-Id                || MailParser::MsgId
|| In-Reply-To               || 文字列または MailParser::MsgId の配列
|| References                || 文字列または MailParser::MsgId の配列
|| Keywords                  || 文字列の配列
|| Resent-Date               || MailParser::DateTime
|| Resent-From               || MailParser::Mailbox の配列
|| Resent-To                 || MailParser::Mailbox または MailParser::Group の配列
|| Resent-Cc                 || MailParser::Mailbox または MailParser::Group の配列
|| Resent-Bcc                || MailParser::Mailbox または MailParser::Group の配列
|| Resent-Message-Id         || MailParser::MsgId
|| Return-Path               || MailParser::Mailbox または nil (<> の場合)
|| Received                  || MailParser::Received
|| Content-Type              || MailParser::ContentType
|| Content-Transfer-Encoding || MailParser::ContentTransferEncoding
|| Content-Id                || MailParser::MsgId
|| Mime-Version              || 文字列
|| Content-Disposition       || MailParser::ContentDisposition

=== body ===

本文文字列を返す。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS))
From: TOMITA Masahiro <tommy@tmtm.org>
Content-Type: text/plain; charset=utf-8

これは本文です。
EOS
m.body  # => "これは本文です。\n"
}}}

=== body_preconv ===

本文の charset変換前文字列を返す。
{{{
m = MailParser::Message.new(<<EOS)
From: TOMITA Masahiro <tommy@tmtm.org>
Content-Type: text/plain; charset=iso-2022-jp

\e$B$3$l$OK\\J8$G$9\e(B
EOS
m.body           # => "これは本文です\n"
m.body_preconv   # => "\e$B$3$l$OK\\J8$G$9\e(B\n"
}}}

=== part ===

マルチパートメッセージの場合、各パートを表す MailParser::Message オブジェクトの配列を返す。
マルチパートメッセージでない場合は空配列を返す。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS, :output_charset=>"utf8"))
Content-Type: multipart/mixed; boundary="abcdefg"

--abcdefg
Content-Type: text/plain

first part.
--abcdefg
Content-Type: text/plain

second part.
--abcdefg--
EOS
m.part.size    # => 2
m.part[0]      # => 最初のパートの MailParser::Message オブジェクト
m.part[1]      # => ２番目のパートの MailParser::Message オブジェクト
}}}

=== message ===

:extract_message_type=>true で message タイプのメッセージの場合、本文が示すメッセージの Mailparser::Message オブジェクトを返す。
:extract_message_type=>false または message タイプでない場合は nil を返す。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS), :extract_message_type=>true)
Content-Type: message/rfc822

Subject: message subject

message body
EOS
m.message.subject  # => "message subject"
}}}

=== rawheader ===

ヘッダ部文字列をパースせずにそのまま返す。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS))
From: TOMITA Masahiro <tommy@tmtm.org>
To: foo@example.com
Subject: subject

body message
EOS
m.rawheader  # => "From: TOMITA Masahiro <tommy@tmtm.org>\nTo: foo@example.com\nSubject: subject\n"
}}}

=== raw ===

生メッセージ文字列を返す。:keep_raw=>true である必要がある。
:keep_raw=>false の場合は空文字列が返る。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS), :keep_raw=>true)
From: TOMITA Masahiro <tommy@tmtm.org>
To: foo@example.com
Subject: subject

body message
EOS
m.rawheader  # => "From: TOMITA Masahiro <tommy@tmtm.org>\nTo: foo@example.com\nSubject: subject\n"
}}}

== MailParser::Header ==

同じ名前を持つヘッダを表すクラス。

=== add(name, body) ===
name ヘッダの値として body を追加する。

=== [](name) ===
name ヘッダの値をパースした結果オブジェクトの配列を返す。
パース結果オブジェクトは raw メソッドを持ち、パース前文字列を取り出すことができる。

=== raw(name) ===
name ヘッダの値のパース前の文字列の配列を返す。

=== keys ===
ヘッダ名文字列の一覧を返す。

=== key?(name) ===
name ヘッダがあれば真。

=== each {|n,v| } ===
各ヘッダについてブロックを繰り返す。
ブロック引数は、１番目がヘッダ名文字列、２番目がパース結果オブジェクトの配列。

== MailParser::DateTime ==

Date ヘッダを表すクラス。

=== year ===

年を表す整数。

=== month ===

月を表す整数。

=== day ===

日を表す整数。

=== hour ===

時を表す整数。

=== min ===

分を表す整数。

=== sec ===

秒を表す整数。

=== zone ===

タイムゾーンを表す文字列。「+9999」または「-9999」の形式。

=== time ===

Time オブジェクトを返す。範囲外の日付の場合は :strict が false でも ArgumentError 例外が発生するので注意。

== MailParser::Mailbox ==

メールアドレスを表すクラス。

=== addr_spec ===

メールアドレスを表す MailParser::AddrSpec を返す。

=== local_part ===

ローカルパートを表す文字列。
MailParser::Mailbox#addr_spec.local_part と同じ。

=== domain ===

ドメインを表す文字列。
addr_spec.domain と同じ。

=== display_name ===

表示名を表す文字列。

=== phrase ===

display_name と同じ。

== MailParser::Group ==

グループアドレスを表すクラス。

=== mailbox_list ===

MailParser::Mailbox の配列。

=== display_name ===

表示名を表す文字列。

=== phrase ===

display_name と同じ。

== MailParser::MsgId ==

=== msg_id ===

メッセージID文字列。先頭と末尾の < > は含まない。

== MailParser::Received ==

Received ヘッダを表すクラス。

=== name_val ===

Received ヘッダ中の名前(小文字の文字列)と値(文字列)の組を表す Hash を返す。
{{{
m = MailParser::Message.new(StringIO.new(<<EOS))
Received: from mx1.tmtm.org (localhost [127.0.0.1])
        by mx2.tmtm.org (Postfix) with ESMTP id 3ED69108383
        for <tommy@tmtm.org>; Tue, 16 Jan 2007 14:20:23 +0900 (JST)
EOS
r = m.header["received"][0]
r.name_val["from"]    # => "mx1.tmtm.org"
r.name_val["by"]      # => "mx2.tmtm.org"
r.name_val["with"]    # => "ESMTP"
r.name_val["for"]     # => "tommy@tmtm.org"
}}}

=== date_time ===

Received ヘッダ中の日時を表す MailParser::DateTime オブジェクトを返す。

== MailParser::ContentType ==

Content-Type ヘッダのパラメータを表すクラス。

=== type ===

Content-Type ヘッダのタイプを表す小文字の文字列を返す。

=== subtype ===

Content-Type ヘッダのサブタイプを表す小文字の文字列を返す。

=== params ===

Content-Type ヘッダのパラメータを表す Hash を返す。
Hash のキーは小文字の文字列。値は文字列。

== MailParser::ContentTransferEncoding ==

Content-Transfer-Encoding ヘッダを表すクラス。

=== mechanism ===

Content-Transfer-Encoding ヘッダの値を小文字の文字列で返す。

== MailParser::ContentDisposition ==

=== type ===

Content-Disposition ヘッダのタイプを表す小文字の文字列を返す。

=== params ===

Content-Disposition ヘッダのパラメータを表す Hash を返す。
Hash のキーは小文字の文字列。値は文字列。

== MailParser::AddrSpec ==

メールアドレスを表すクラス。

=== local_part ===

メールアドレスのローカルパート文字列を返す。

=== domain ===

メールアドレスのドメイン部文字列を返す。
