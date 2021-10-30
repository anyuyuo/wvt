require 'sinatra'
require 'json'
require 'image_processing/mini_magick'

set :port, 4444
set :bind, '0.0.0.0'
root_dir = ARGV[0] ? ARGV[0] : 'some default path'
domain = 'meatball.example.com'

puts "Serving: #{root_dir}"

# shared links, auto delete after a few days?
# {  }
# [ ]
# { link => 'some outside link', path => 'path to be shared' }
shared = []

get '/' do
    logger.info 'getting images from ' + root_dir
    'hello world!'
end

get '/browse' do
    if !params['path'] then
        status 400
        redirect '/browse?path=/'
    end
    
    send_file 'browse.html'
end

# scaled down version of image
get '/api/image/small' do
    if !params['path'] then
        status 400
        return 'missing path'
    end
    path = root_dir + params['path']

    # todo: make global working dir and escape all '..'
    file = open(path)
    processed = ImageProcessing::MiniMagick
        .source(file)
        .resize_to_limit(1200, 1200)
        .call()
    
    content_type 'image/jpg'
    processed.read
end

# full image
get '/api/image/full' do
    if !params['path'] then
        status 400
        return 'missing path'
    end
    path = root_dir + params['path']


    send_file path
end

# list dir for other dirs and images and videos
# TODO: generate link for dir, so the client doesn't always has to make
get '/api/list' do
    if !params['path'] then
        status 400
        return 'missing path'
    end
    sub_path = params['path'].gsub("..", "")
    path = root_dir + sub_path

    if !Dir.exist?(path) then
        status 400
        return 'Dir does not exist'
    end

    d_content = Dir.entries path

    d_content.delete('..')
    d_content.delete('.')

    file_exts = ['png', 'jpg', 'jpeg', 'mp4', 'webp', 'gif', 'webm']

    directories = d_content.select { |some| Dir.exist?(path + '/' + some) }
    images      = d_content.select do |some| 
        valid = false
        file_exts.each do |ext|
            valid = true if some.downcase().end_with?(ext)
        end
        valid
    end

    directories.sort!
    images.sort!

    r = {:path => sub_path  , :directories => directories, :images => images}
    
    content_type = 'text/json'
    JSON.pretty_generate(r)
end

get '/some_funky_dir_icon.png' do
    send_file 'folder.png'
end