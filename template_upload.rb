#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# レシートプリンタ用のファイルをzip圧縮してHTTP経由でアップロードする
# 2012/08/09 Satoshi Akama
#
# インストール 
# Rubyが入っている必要があります。1.9.3で動作確認。1.8系では動かないかも。
# http://www.ruby-lang.org/ja/downloads/
# 
# WindowsでもRubyの実行環境入れればたぶん動きます。
# http://rubyinstaller.org/
#
# httpclientライブラリを使用しているので
# gem install httpclient
# してインストールしてください。
# 1.9系はRubyGemsがバンドルされているので上記コマンドのみでOK。1.8系はRubyGems自体のインストールが必要
# http://rubygems.org/
# 
# 
# 使用方法
# chmod a+x /path/to/upload.rb
# 任意のディレクトリ
# ├upload.rb
# └receit/
#   ├ stylesheet/
#   ├ images
#   ├ ....
#   └ ....
# 
# 下の方にある各種設定を各自のパスに合わせて修正
# 実行
# ./upload.rb

require "httpclient"
require "fileutils"
require 'zipruby'
require 'optparse'
require "uri"

####各種設定
#テンプレートファイルのパス(相対パスでも絶対パスでもOK)
template_filepath = "./PrinterUpload/"

#共有アップロード用ディレクトリ
printer_upload_path = '/tmp/PrinterUpload'

#zip圧縮後のファイル名(相対パスでも絶対パスでもOK)
zip_filepath = 'receit.zip'

#プリンタのIP
printer_ip = "192.168.1.1"

class UploadDataToPrinter
  #ファイルをコピーするメソッド(stylesheetだけコピー)
  def self.file_copy(src_filepath, dest_filepath)
    FileUtils.cp_r("#{src_filepath}stylesheet/", "#{dest_filepath}", 
                   {noop: false, verbose: true, preserve: true})
  end

  #HTTP/POSTでファイルをアップロードするメソッド
  def self.file_upload(hostname, upload_file_name)
    uri = "http://" + hostname + "/upload_web_contents_updater.cgi"
    boundary = "123456"
    req = HTTPClient.new
    open(upload_file_name) do |file|
      postdata = {"FileName" => file}
      req.post_content(uri, postdata)
    end
  end

  #zip圧縮するメソッド
  def self.compress(compress_filepath, target_filepath)
    Zip::Archive.open("#{compress_filepath}", Zip::CREATE) do |ar|
      Dir::chdir("#{target_filepath}") do |dir|
        Dir.glob("./*/*").each do |path|
          if File.directory?(path)
            ar.add_dir(path)
          else
            ar.add_file(path, path) # add_file(<entry name>, <source path>)
          end
        end
      end
    end
    #    result = system("(cd #{target_filepath} && zip -r #{compress_filepath} .) > /dev/null")
    # if !result
    #   puts 'エラー：zip圧縮に失敗'
    #   exit(1)
    # else
    #   puts 'zip圧縮完了'
    # end
  end

  #アップロード処理完了後にファイルを削除するメソッド
  def self.rm_zipfile(filepath)
    FileUtils.remove(filepath)
  end
end

#####処理開始
template_filepath = File::expand_path(template_filepath) + '/'
printer_upload_path = File::expand_path(printer_upload_path) + '/'
zip_temp_filepath = File::expand_path(zip_filepath) + '/'
zip_dir = File::dirname(zip_temp_filepath)
zip_filename = File::basename(zip_temp_filepath)
zip_filepath = zip_dir + '/' + zip_filename

OPTS = {}

OptionParser.new do |opt|
  opt.on('-n', '--no-copy', 'no copy template files') {|v| OPTS[:nocopy] = true }
  opt.parse!(ARGV)
end

if !OPTS[:nocopy]
  if !File.exist?(template_filepath)
    puts 'エラー：テンプレートファイルのディレクトリが存在しません'
    exit(1)
  end
end

if !File.exist?(printer_upload_path)
  puts 'エラー：共有アップロード用ディレクトリが存在しません'
  exit(1)
end

if !OPTS[:nocopy]
  #ファイルコピー
  UploadDataToPrinter.file_copy(template_filepath, printer_upload_path)
end
#zip圧縮
UploadDataToPrinter.compress(zip_filepath, printer_upload_path)
puts 'zip圧縮完了'
#HTTP/POSTを開始
UploadDataToPrinter.file_upload(printer_ip, zip_filepath)
#圧縮ファイルを削除
UploadDataToPrinter.rm_zipfile(zip_filepath)
puts 'Upload処理完了'
