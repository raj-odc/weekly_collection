class Loan < ActiveRecord::Base
  extend Enumerize
  belongs_to :customer
  has_many :daily_collections, dependent: :destroy

  paginates_per 20

  default_scope { order(order_no: :asc) }

  before_save :auto_increment
  before_create :auto_increment
  before_save  :update_balance
  before_create :update_balance

  enumerize :loan_type,
            in: {Weekly: 1,
                 Daily: 2
            }, scope: true

  scope :weekly, -> { with_loan_type :Weekly }
  scope :daily, -> { with_loan_type :Daily }

  scope :active, -> { where(:active_status => true) }
  scope :inactive, -> { where(:active_status => false) }

  scope :customer_name, ->(name) { joins(:customer).where('lower(customers.name) like ?', "%#{name.downcase}%") }

  enumerize :vasool_day,
            in: {Sunday: 1,
                 Monday: 2,
                 Tuesday: 3,
                 Wednesday: 4,
                 Thursday: 5,
                 Friday: 6,
                 Saturday: 7
            }, scope: true

  scope :sunday, -> { with_vasool_day :Sunday }
  scope :monday, -> { with_vasool_day :Monday }
  scope :tuesday, -> { with_vasool_day :Tuesday }
  scope :wednesday, -> { with_vasool_day :Wednesday }
  scope :thursday, -> { with_vasool_day :Thursday }
  scope :friday, -> { with_vasool_day :Friday }
  scope :saturday, -> { with_vasool_day :Saturday }


  def self.search_name_day(query, day)
    customer_name(query).send(day)
  end

  def self.search_name(query)

    customer_name(query)
  end

  def update_balance_amount(balance)
    paid_amount = loan_amount - balance
    update(:balance_amount => balance, :paid_amount => paid_amount)
  end

  def calculate_weeks
    days = (Date.today - given_date).to_i
    days/7
  end

  def due_in_weeks
    installments - calculate_weeks
  end

  def self.total_paid(date)
    where(:given_date => date).map(&:given_amount).reduce(:+) || 0
  end


  def auto_increment
    loan = Loan.find_by_order_no(order_no)
    if loan && loan!=self
      @loan_all = Loan.where("order_no >= #{self.order_no}")
      @loan_all.each {|loan| loan.update_attribute(:order_no, loan.order_no+1)}
    end
  end

  def update_balance
    self.balance_amount = self.loan_amount - self.paid_amount
  end
end
