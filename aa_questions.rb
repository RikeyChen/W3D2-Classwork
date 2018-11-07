require 'sqlite3'
require 'singleton'
require 'active_support/inflector'
require "byebug"

class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class ModelBase
  def self.find_by_id(id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.to_s.tableize.downcase}
      WHERE
        id = ?
    SQL
    self.new(data.first)
  end

  def self.all
    data = QuestionsDBConnection.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.to_s.tableize.downcase}
    SQL
    data.map { |datum| self.new(datum) } unless data.empty?
  end

  def self.where(options)
    records = QuestionsDBConnection.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.to_s.tableize.downcase}
      WHERE
        #{options.map { |k, v| "#{k} = #{v}"}.join(" AND ")}
    SQL

    records.map { |record_datum| self.new(record_datum) } unless records.empty?
  end

  def save
    if @id
      instance_variables = self.instance_variables
      instance_variables.delete(:@id)
      set_statement = instance_variables.map { |var| "#{var.to_s[1..-1]} = '#{self.instance_variable_get(var)}'" }.join(", ")

      debugger
      QuestionsDBConnection.instance.execute(<<-SQL, @id)
        UPDATE
          #{self.class.to_s.tableize.downcase}
        SET
          #{set_statement}
        WHERE
          id = ?
      SQL
    else
      instance_variables = self.instance_variables
      instance_variables.delete(:@id)
      update_columns = instance_variables.map { |var| "#{var.to_s[1..-1]}" }.join(", ")
      values = instance_variables.map { |var| self.instance_variable_get(var) }
      question_marks = instance_variables.map { |var| "?" }.join(", ")

      QuestionsDBConnection.instance.execute(<<-SQL, *values)
        INSERT INTO
          #{self.class.to_s.tableize.downcase} (#{update_columns})
        VALUES
          (#{question_marks})
      SQL
      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end
end

class Question < ModelBase
  attr_accessor :title, :body, :user_id

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  # def self.find_by_id(id)
  #   question = QuestionsDBConnection.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       questions
  #     WHERE
  #       id = ?
  #   SQL
  #   Question.new(question.first)
  # end

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

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
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

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  # def save
  #   if @id
  #     QuestionsDBConnection.instance.execute(<<-SQL, @title, @body, @user_id, @id)
  #       UPDATE
  #         questions
  #       SET
  #         title = ?, body = ?, user_id = ?
  #       WHERE
  #         id = ?
  #     SQL
  #   else
  #     QuestionsDBConnection.instance.execute(<<-SQL, @title, @body, @user_id)
  #       INSERT INTO
  #         questions (title, body, user_id)
  #       VALUES
  #         (?, ?, ?)
  #     SQL
  #     @id = QuestionsDBConnection.instance.last_insert_row_id
  #   end
  # end
end


class Reply < ModelBase
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

  # def save
  #   if @id
  #     QuestionsDBConnection.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body, @id)
  #       UPDATE
  #         replies
  #       SET
  #         question_id = ?, parent_id = ?, user_id = ?, body = ?
  #       WHERE
  #         id = ?
  #     SQL
  #   else
  #     QuestionsDBConnection.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body)
  #       INSERT INTO
  #         replies (question_id, parent_id, user_id, body)
  #       VALUES
  #         (?, ?, ?, ?)
  #     SQL
  #     @id = QuestionsDBConnection.instance.last_insert_row_id
  #   end
  # end

end

class User < ModelBase
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

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    avg_karma = QuestionsDBConnection.instance.execute(<<-SQL, @id)
      SELECT
        CAST(COUNT(question_likes.user_id) AS FLOAT) / COUNT(DISTINCT(questions.id))
      FROM
        questions
      LEFT OUTER JOIN
        question_likes
      ON
        questions.id = question_likes.question_id
      WHERE
        questions.user_id = ?
    SQL

    avg_karma.first.values.first
  end


  # def save
  #   if @id
  #     QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname, @id)
  #       UPDATE
  #         users
  #       SET
  #         fname = ?, lname = ?
  #       WHERE
  #         id = ?
  #     SQL
  #   else
  #     QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname)
  #       INSERT INTO
  #         users (fname, lname)
  #       VALUES
  #         (?, ?)
  #     SQL
  #     @id = QuestionsDBConnection.instance.last_insert_row_id
  #   end
  # end
end

class QuestionFollow
  attr_accessor :user_id, :question_id

  def self.followers_for_question_id(question_id)
    followers = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
      JOIN
        question_follows
      ON
        question_follows.user_id = users.id
      JOIN
        questions
      ON
        questions.id = question_follows.question_id
      WHERE
        questions.id = ?
    SQL
    followers.map { |follower_data| User.new(follower_data) } unless followers.empty?
  end

  def self.followed_questions_for_user_id(user_id)
    followed_questions = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        users
      JOIN
        question_follows
      ON
        question_follows.user_id = users.id
      JOIN
        questions
      ON
        questions.id = question_follows.question_id
      WHERE
        users.id = ?
    SQL
    followed_questions.map { |question_datum| Question.new(question_datum) } unless followed_questions.empty?
  end

  def self.most_followed_questions(n)
    questions = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT
        questions.*
      FROM
        users
      JOIN
        question_follows
      ON
        question_follows.user_id = users.id
      JOIN
        questions
      ON
        questions.id = question_follows.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(*) DESC
      LIMIT
        ?
    SQL
    questions.map { |question_datum| Question.new(question_datum) } unless questions.empty?

  end
end

class QuestionLike

  def self.likers_for_question_id(question_id)
    likers = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
      JOIN
        question_likes
      ON
        users.id = question_likes.user_id
      JOIN
        questions
      ON
        questions.id = question_likes.question_id
      WHERE
        questions.id = ?
    SQL
    likers.map { |likers_datum| User.new(likers_datum) } unless likers.empty?
  end

  def self.num_likes_for_question_id(question_id)
    count = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(users.id)
      FROM
        users
      JOIN
        question_likes
      ON
        users.id = question_likes.user_id
      JOIN
        questions
      ON
        questions.id = question_likes.question_id
      WHERE
        questions.id = ?
      GROUP BY
        questions.id

    SQL
    count.first.values.first
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        users
      JOIN
        question_likes
      ON
        users.id = question_likes.user_id
      JOIN
        questions
      ON
        questions.id = question_likes.question_id
      WHERE
        users.id = ?
      GROUP BY
        users.id

    SQL
    questions.map { |question_datum| Question.new(question_datum) } unless questions.empty?
  end

  def self.most_liked_questions(n)
    questions = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT
        questions.*
      FROM
        users
      JOIN
        question_likes
      ON
        users.id = question_likes.user_id
      JOIN
        questions
      ON
        questions.id = question_likes.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(users.id) DESC
      LIMIT ?
    SQL

    questions.map { |question_datum| Question.new(question_datum) } unless questions.empty?
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
