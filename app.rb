#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require "sqlite3"

# функция которая создает глобальную базу... и она во 2-ой строке возвращается в хеш
def init_db
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end	

# вызывается каждый раз при перезагрузке любой страницы (не исполняется для CONFIGURE DO)
before do
	# инициализация БД
	init_db 
end

# вызывается каждый раз при конфигурации приложения (изменился код или перезагрузилась страница)
configure do
	# инициализация БД
	init_db

	# создает таблицу если таблицы не существует
	@db.execute 'CREATE TABLE IF NOT EXISTS Posts 
		(
   			 id           INTEGER PRIMARY KEY AUTOINCREMENT,
   			 created_date DATE,
   			 content      TEXT
		)'

	@db.execute 'CREATE TABLE IF NOT EXISTS Comments 
		(
   			 id           INTEGER PRIMARY KEY AUTOINCREMENT,
   			 created_date DATE,
   			 content      TEXT,
   			 post_id  	  INTEGER	
		)'	
end	

get '/' do
	# выбираем список постов из БД
	@results = @db.execute 'select * from Posts order by id desc'

	erb :index
end

#обработчик get-запроса /new (браузер получает страницу на сервер)
get '/new' do
  	erb :new
end

#обработчик post-запроса /new (браузер отправляет данные на сервер)
post '/new' do
	#получаем переменную из post-запроса
	content = params[:content]

	if content.length <= 0
		@error = 'Введите текст'
		return erb :new 
	end 

	#сохранение данных в БД
	@db.execute 'insert into Posts (content, created_date) values (?, datetime())', [content]


	# перенаправлениеп на главную страницу
	redirect to '/'
end

# вывод информации о посте

get '/details/:post_id' do
	# получаем переменную из URL'а
	post_id = params[:post_id]

	# получаем список постов (у нас будет только один пост)
	results = @db.execute 'select * from Posts where id = ?', [post_id]

	# выбираем этот один пост в переменную @row
	@row = results[0]

	#выбираем комментарии для нашего поста
	@comments = @db.execute 'select * from Comments where post_id = ? order by id', [post_id]

	# возвращаем представление details.erb
	erb :details
end	


# обработчик post-запроса(браузер отправляет данные на сервер, а мы их принимаем)
post '/details/:post_id' do
	# получаем переменную из URL'а
	post_id = params[:post_id]

	#получаем переменную из post-запроса
	content = params[:content]

	#сохранение данных в БД
	@db.execute 'insert into Comments 
		(content, created_date, post_id) 
			values (?, datetime(), ?)', [content, post_id]

	# перенаправлениеп на страницу поста
	redirect to ('/details/' + post_id)	
end 	
