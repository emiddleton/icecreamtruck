FactoryBot.define do
  factory :order do
    name { Faker::Name.name }

    order_items do
      Array.new(Faker::Number.within(range: 1..4)) { association(:order_item) }
    end

    payment do
      i = Payment.new
      i.card_number = Faker::Finance.credit_card
      i.expiry_date = Faker::Date.between(from: 2.years.from_now, to: 10.years.from_now).strftime('%y-%m')
      i
    end
  end
end
