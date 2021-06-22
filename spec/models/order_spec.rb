require 'rails_helper'

RSpec.describe Order, type: :model do
  describe '#handle_payment!' do
    context 'with valid data and no server issues' do
      it 'reserves required stock and handles payment' do
      end
    end
    context 'when #reserve_stock! fails' do
      context 'because of insufficient stock' do
        it 'raises and exception and cancels order' do
        end
      end
    end
    context 'when #process_payment! fails' do
      context 'because of network issue' do
        it 'raises and exception and cancels order' do
        end
      end
      context 'because application crashes' do
        it 'leaves order in :processing state' do
        end
      end
    end
  end
  describe '#complete_sale!' do
    context 'when '
  end
  describe '#cancel!' do
    context 'when '
  end
end
