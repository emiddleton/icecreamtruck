FactoryBot.define do
  factory :item do
    name do
      [
        'Bacon',
        'Banana',
        'Bastani sonnati',
        'Beer',
        'Blue Heaven',
        'Blue moon',
        'Butter Brickle',
        'Butter pecan',
        'Cheese',
        'Cherry',
        'Chocolate',
        'Chocolate Chip cookie dough',
        'Coffee',
        'Cookie dough',
        'Cookies and cream',
        'Cotton candy',
        'Crab',
        'Creole cream cheese',
        'Dulce de leche',
        'Earl Grey',
        'French vanilla',
        'Garlic',
        'Grape',
        'Green tea',
        'Halva',
        'Hokey pokey',
        'Lucuma',
        'Mamey',
        'Mango',
        'Mint chocolate chip',
        'Moon mist',
        'Meapolitan',
        'Oyster',
        'Pistachio',
        'Peanut butter',
        'Raspberry Ripple',
        'Rocky road',
        'Spumoni',
        'Stracciatella',
        'Strawberry',
        'Superman',
        'Teaberry',
        'Tiger tail',
        'Tutti frutti',
        'Ube',
        'Vanilla'
      ].sample
    end
    price { Faker::Number.within(range: 100..1000) }
    quantity { Faker::Number.within(range: 50..1000) }
    sales { price * Faker::Number.within(range: 20..500) }
  end
end
