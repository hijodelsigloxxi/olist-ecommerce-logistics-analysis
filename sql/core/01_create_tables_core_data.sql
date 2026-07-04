CREATE SCHEMA core;

CREATE TABLE core.geolocations (
    geolocation_zip_code_prefix text PRIMARY KEY,
    geolocation_lat double precision ,
    geolocation_lng double precision ,
    geolocation_city text ,
    geolocation_state text 
);

CREATE TABLE core.customers(
customer_id text primary key,
customer_unique_id text not null,
customer_zip_code_prefix text not null,
customer_city text not null,
customer_state text not null,
foreign key (customer_zip_code_prefix) references core.geolocations(geolocation_zip_code_prefix)
)

CREATE TABLE core.sellers (
seller_id text primary key,
seller_zip_code_prefix text not null,
seller_city text not null,
seller_state text not null,
foreign key(seller_zip_code_prefix) references core.geolocations(geolocation_zip_code_prefix)
)

CREATE TABLE core.products (
    product_id text PRIMARY KEY,
    product_category_name text,
    product_name_lenght double precision,
    product_description_lenght double precision,
    product_photos_qty double precision,
    product_weight_g double precision,
    product_length_cm double precision,
    product_height_cm double precision,
    product_width_cm double precision
);

CREATE TABLE core.orders (
    order_id text PRIMARY KEY,
    customer_id text NOT NULL,
    order_status text NOT NULL,
    order_purchase_timestamp timestamp NOT NULL,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES core.customers(customer_id)
);

CREATE TABLE core.order_items (
    order_id text NOT NULL,
    order_item_id int NOT NULL,
    product_id text NOT NULL,
    seller_id text NOT NULL,
    shipping_limit_date timestamp NOT NULL,
    price double precision NOT NULL,
    freight_value double precision NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES core.orders(order_id),
    FOREIGN KEY (product_id) REFERENCES core.products(product_id),
    FOREIGN KEY (seller_id) REFERENCES core.sellers(seller_id)
);

CREATE TABLE core.order_payments (
    order_id text NOT NULL,
    payment_sequential int NOT NULL,
    payment_type text NOT NULL,
    payment_installments int NOT NULL,
    payment_value double precision NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES core.orders(order_id)
);



CREATE TABLE core.order_reviews (
    review_id text NOT NULL,
    order_id text NOT NULL,
    review_score int NOT NULL,
    review_comment_title text,
    review_comment_message text,
    review_creation_date timestamp NOT NULL,
    review_answer_timestamp timestamp NOT NULL,
    FOREIGN KEY (order_id) REFERENCES core.orders(order_id)
);


