# frozen_string_literal: false

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
Item.create(
  [
    { name: 'Chocolate',  price: 100, quantity: 200, sales: 5000 },
    { name: 'Pistachio',  price: 120, quantity: 100, sales: 3000 },
    { name: 'Strawberry', price: 100, quantity: 200, sales: 5000 },
    { name: 'Mint',       price: 100, quantity: 100, sales: 2000 }
  ]
)
