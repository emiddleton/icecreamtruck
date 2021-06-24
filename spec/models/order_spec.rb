require 'rails_helper'

RSpec.describe Order, type: :model do
  describe '#handle_payment!' do
    context 'with valid data and no server issues' do
      it 'reserves required stock and handles payment' do
        order = build(:order)
        allow(order).to receive(:reserve_stock!).once
        allow(order).to receive(:request_payment!).once
        order.handle_payment!
      end
    end
    context 'when #reserve_stock! fails' do
      context 'because of insufficient stock' do
        it 'raises and exception and cancels order' do
          order = build(:order)
          order.order_items.first.item.update(quantity: 0)
          expect { order.handle_payment! }.to raise_error(ActiveRecord::RecordInvalid)
          expect(order.status).to eq('canceled')
        end
      end
    end
    context 'when #process_payment! fails' do
      context 'because of network issue' do
        it 'raises and exception and cancels order' do
          order = build(:order)
          allow(order).to receive(:payment_provider!).and_raise(PaymentException)
          expect { order.handle_payment! }.to raise_error(PaymentException)
          expect(order.status).to eq('check_refund')
        end
      end
    end
  end
  describe '#complete_sale!' do
    context 'when status.payed' do
      it 'handles sales update and sets status.completed' do
        order = build(:order)
        order.handle_payment!
        order.order_items.each do |oi|
          allow(oi).to receive(:account_for_sales!).once
        end
        order.complete_sale!
        expect(order.status).to eq('completed')
      end
    end
    %i[reserved paying refunding completed canceled check_refund].each do |s|
      context "when not status.#{s}" do
        it 'raises and exception' do
          order = build(:order)
          order.handle_payment!
          order.update_attribute(:status, s)
          expect { order.complete_sale! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
  describe '#cancel!' do
    context 'when status.completed' do
      it 'revert all and level in canceled state' do
        order = build(:order)
        order.handle_payment!
        order.complete_sale!
        allow(order).to receive(:revert_sale!).once
        allow(order).to receive(:revert_payment!).once
        allow(order).to receive(:return_stock!).once
        order.cancel!
        order.reload
      end
    end
    context 'when status.paying' do
      it 'returns stock and set status.check_refund' do
        order = build(:order)
        order.handle_payment!
        order.update_attribute(:status, :paying)
        allow(order).to receive(:return_stock!).once
      end
    end
  end
end
