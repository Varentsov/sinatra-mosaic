require 'ffi'
require 'sinatra'

module Mosaic
  extend FFI::Library
  ffi_lib 'lib/libmosaic_embed.so'
  attach_function :main_work, [:string, :bool, :string, :bool], :int
end

# Scan images dir for new images
#Mosaic.main_work("", true, "path to images directory", false)

# Initializing

if !Dir.exist?("uploads")
  Dir.mkdir("uploads")
end
if !Dir.exist?("results")
  Dir.mkdir("results")
end


configure do
  set :port, 3000
  set :bind, '0.0.0.0'
  set :public_folder, File.dirname(__FILE__) + '/results/'
end

get '/' do
  erb :index
end

post '/process' do
  file_name = Time.now.strftime("%m%H%M%S") + File.basename(params[:image][:filename], '.*').gsub('.', '_') + File.extname(params[:image][:filename])

  path = 'uploads/' + file_name
  File.open(path, "w") do |f|
    f.write(params[:image][:tempfile].read)
  end

  new_path = File.expand_path(path)

  result = Mosaic.main_work(new_path, false, "", false)

  if result != 0
    redirect "/error?error=Cant open your image"
    return
  end

  result = File.basename(new_path, '.*') + '.png'
  redirect to("/result?result=#{result}")
end

get '/result' do
  @result = params[:result].to_s

  if !File.exist?('results/' + @result)
    redirect "/error?error=File not found"
    return
  end

  erb :output
end

get '/error' do
  erb params[:error].to_s
end
