RSpec.shared_context 'json' do
  def json_headers
    { Accept: 'application/json', "Content-type": 'application/json' }
  end

  def json_expected_response(status = :ok)
    expect(response.content_type).to eq('application/json; charset=utf-8')
    expect(response).to have_http_status(status)
  end

  def get_json(path, arguments = nil, status = :ok)
    get path, params: arguments, headers: json_headers
    json_expected_response(status)
  end

  def put_json(path, arguments = nil, status = :ok)
    put path, params: arguments, headers: json_headers
    json_expected_response(status)
  end

  def post_json(path, arguments = nil, status = :created)
    post path, params: arguments, headers: json_headers
    json_expected_response(status)
  end

  def delete_json(path, arguments = nil, status = :no_content)
    delete path, params: arguments, headers: json_headers
    expect(response).to have_http_status(status)
  end
end

RSpec.shared_context 'items' do
  before(:context) do
    Item.create(
      [
        { name: 'Chocolate',  price: 100, quantity: 200, sales: 5000 },
        { name: 'Pistachio',  price: 120, quantity: 100, sales: 3000 },
        { name: 'Strawberry', price: 100, quantity: 200, sales: 5000 },
        { name: 'Mint',       price: 100, quantity: 100, sales: 2000 }
      ]
    )
  end

  after(:context) do
    Item.destroy_all
  end
end
