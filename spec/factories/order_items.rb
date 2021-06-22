FactoryBot.define do
  factory :order_item do
    quantity { Faker::Number.within(range: 1..10) }
    item { create(:item) }
  end
end
