# frozen_string_literal: false

class CreateOrders < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
      CREATE TYPE public.order_status AS ENUM (
        'reserved',
        'paying',
        'refunding',
        'payed',
        'completed',
        'canceled',
        'check_refund'
      );

      CREATE TABLE public.orders(
        id uuid DEFAULT gen_random_uuid() NOT NULL,
        name TEXT NOT NULL,
        status public.order_status NOT NULL,
        request_id uuid NOT NULL,
        transaction_id uuid DEFAULT gen_random_uuid() NOT NULL,
        created_at TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL
      );

      CREATE UNIQUE INDEX index_unique_order ON public.orders USING btree (request_id);
      ALTER TABLE ONLY public.orders ADD CONSTRAINT orders_pkey PRIMARY KEY (id);
    SQL
  end

  def down
    execute <<-SQL.squish
      DROP TABLE public.orders;
      DROP TYPE public.order_status;
    SQL
  end
end
