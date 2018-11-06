require 'sqlite3'
require 'singleton'

class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Question
  attr_accessor :title, :body, :user_id

  def self.find_by_id(id)
    question = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    Question.new(question.first)
  end

  def self.find_by_author_id(author_id)
    question = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        user_id = ?
    SQL
    Question.new(question.first)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end

  def author
    authors = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    User.new(authors.first)
  end

  def replies
    Reply.find_by_question_id(@id)
  end
end


class Reply
  attr_accessor :question_id, :parent_id, :user_id, :body

  def self.find_by_user_id(user_id)
    replies = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
    replies.map { |reply_data| Reply.new(reply_data) }
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    replies.map { |reply_data| Reply.new(reply_data) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @body = options['body']
    @user_id = options['user_id']
    @parent_id = options['parent_id']
  end

  def author
    authors = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    User.new(authors.first)
  end

  def question
    Question.find_by_id(question_id)
  end

  def parent_reply
    parent_reply = QuestionsDBConnection.instance.execute(<<-SQL, parent_id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    Reply.new(parent_reply.first) unless parent_reply.empty?
  end

  def child_replies
    child_replies = QuestionsDBConnection.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
    child_replies.map { |child_reply_data| Reply.new(child_reply_data) } unless child_replies.empty?
  end

end

class User
  attr_accessor :fname, :lname

  def self.find_by_name(fname, lname)
    users = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    User.new(users.first)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end
end



#   def self.all
#     data = QuestionsDBConnection.instance.execute("SELECT * FROM plays")
#     data.map { |datum| Play.new(datum) }
#   end
#
#   def self.find_by_title(title)
#     play = QuestionsDBConnection.instance.execute(<<-SQL, title)
#       SELECT
#         *
#       FROM
#         plays
#       WHERE
#         title = ?
#     SQL
#     return nil unless play.length > 0
#
#     Play.new(play.first) # play is stored in an array!
#   end
#
#   def self.find_by_playwright(name)
#     playwright = Playwright.find_by_name(name)
#     raise "#{name} not found in DB" unless playwright
#
#     plays = QuestionsDBConnection.instance.execute(<<-SQL, playwright.id)
#       SELECT
#         *
#       FROM
#         plays
#       WHERE
#         playwright_id = ?
#     SQL
#
#     plays.map { |play| Play.new(play) }
#   end
#
#   def initialize(options)
#     @id = options['id']
#     @title = options['title']
#     @year = options['year']
#     @playwright_id = options['playwright_id']
#   end
#
#   def create
#     raise "#{self} already in database" if @id
#     QuestionsDBConnection.instance.execute(<<-SQL, @title, @year, @playwright_id)
#       INSERT INTO
#         plays (title, year, playwright_id)
#       VALUES
#         (?, ?, ?)
#     SQL
#     @id = QuestionsDBConnection.instance.last_insert_row_id
#   end
#
#   def update
#     raise "#{self} not in database" unless @id
#     QuestionsDBConnection.instance.execute(<<-SQL, @title, @year, @playwright_id, @id)
#       UPDATE
#         plays
#       SET
#         title = ?, year = ?, playwright_id = ?
#       WHERE
#         id = ?
#     SQL
#   end
# end
#
# class Playwright
#   attr_accessor :name, :birth_year
#   attr_reader :id
#
#   def self.all
#     data = QuestionsDBConnection.instance.execute("SELECT * FROM playwrights")
#     data.map { |datum| Playwright.new(datum) }
#   end
#
#   def self.find_by_name(name)
#     person = QuestionsDBConnection.instance.execute(<<-SQL, name)
#       SELECT
#         *
#       FROM
#         playwrights
#       WHERE
#         name = ?
#     SQL
#     return nil unless person.length > 0 # person is stored in an array!
#
#     Playwright.new(person.first)
#   end
#
#   def initialize(options)
#     @id = options['id']
#     @name = options['name']
#     @birth_year = options['birth_year']
#   end
#
#   def create
#     raise "#{self} already in database" if @id
#     QuestionsDBConnection.instance.execute(<<-SQL, @name, @birth_year)
#       INSERT INTO
#         playwrights (name, birth_year)
#       VALUES
#         (?, ?)
#     SQL
#     @id = QuestionsDBConnection.instance.last_insert_row_id
#   end
#
#   def update
#     raise "#{self} not in database" unless @id
#     QuestionsDBConnection.instance.execute(<<-SQL, @name, @birth_year, @id)
#       UPDATE
#         playwrights
#       SET
#         name = ?, birth_year = ?
#       WHERE
#         id = ?
#     SQL
#   end
#
#   def get_plays
#     raise "#{self} not in database" unless @id
#     plays = QuestionsDBConnection.instance.execute(<<-SQL, @id)
#       SELECT
#         *
#       FROM
#         plays
#       WHERE
#         playwright_id = ?
#     SQL
#     plays.map { |play| Play.new(play) }
#   end
#
# end
