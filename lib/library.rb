require "date"
require "yaml"
require "./lib/book.rb"

class Library

    attr_accessor :collection, :users

    def initialize
        @collection = set_collection
        @users = set_users
        replace_id
    end
 
    def replace_id
        @collection.each do |book|
            usr = @users.select {|user| user.id == book.loanee}
            usr << nil
            book.loanee=usr[0]
        end
    end

    def set_collection
        (YAML.load_file('./lib/data.yml')).map! {|rawdata|  Book.new(rawdata.merge({library: self}))}
    end

    def set_users
        (YAML.load_file('./lib/users.yml')).map! {|user|  Person.new(user)}
    end

    def add_user(attrs = {})
        attrs[:active] = attrs[:active].nil? ? true : attrs[:active]
        @users << Person.new(attrs)
        update_user_database
        @users[-1]
    end

    def collection_to_hash
        list = @collection.map {|book| book_to_hash(book)}
        list.each {|book| book.delete(:loanee)}
    end

    def printpretty(array_of_books)
        array_of_books.each do |book|
           puts "#{book[:item][:title]} by #{book[:item][:author]} \n #{book[:item][:category]} \t Available:#{book[:available]} \t Return Date: #{book[:return_date]} \n "
        end
        nil
    end

    def list_collection
        printpretty(collection_to_hash)
    end

    def find_title(search_word)
        printpretty(collection_to_hash.select {|book| book[:item][:title].include? search_word})
    end

    def find_author(search_word)
        printpretty(collection_to_hash.select {|book| book[:item][:author].include? search_word})
    end

    def find_category(search_word)
        printpretty(collection_to_hash.select {|book| book[:item][:category].include? search_word})
    end

    def find_available
        printpretty(collection_to_hash.select {|book| book[:available]==true })
    end

    def find_unavailable(user)
        unavail = @collection.select {|book| book.available==false }
        unavail.map! {|book| book_to_hash(book)}
        if user.role == 'User'
            unavail.each {|book| 
                book.delete(:loanee)
            }
        end
        unavail
    end


    def book_to_hash(bookobj)
        personid = bookobj.loanee.nil? ? nil : bookobj.loanee.id     
        {item: {title: bookobj.title, author: bookobj.author,category: bookobj.category }, available: bookobj.available, loanee: personid, return_date: bookobj.return_date }
    end

    def user_to_hash(userobj)
        {name: userobj.name, phone: userobj.phone, role: userobj.role, active: userobj.active, id: userobj.id, born_date: userobj.born_date, no_of_borrowed_books: userobj.receipts.length}
    end

    def write_database
        updated_hash = []
       @collection.each do |book|
           updated_hash << book_to_hash(book)
       end
       File.open('./lib/data.yml', 'w') { |f| f.write updated_hash.to_yaml }
    end

    def update_user_database
        updated_users = []
        @users.each do |user|
            updated_users << user_to_hash(user) 
        end
        File.open('./lib/users.yml', 'w') { |f| f.write updated_users.to_yaml }
    end
    
    def select_book(book_name)
        selected = @collection.select {|book| book.title == book_name}
        selected.nil? ? (raise 'no such book') : selected[0]
    end
end
