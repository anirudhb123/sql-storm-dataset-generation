
WITH customer_data AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        LOWER(c.c_email_address) AS email_lowercase
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_data AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        i.i_current_price,
        i.i_brand,
        i.i_color,
        LENGTH(i.i_item_desc) AS desc_length
    FROM item i
),
sales_data AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        TO_CHAR(DATE '2000-01-01' + dd.d_date) AS sale_date,
        CONVERT(VARCHAR, dd.d_month_seq) AS month_desc
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
),
sales_summary AS (
    SELECT
        cd.full_name,
        cd.email_lowercase,
        cd.ca_city,
        cd.ca_state,
        COUNT(sd.ws_order_number) AS total_orders,
        SUM(sd.ws_sales_price) AS total_sales,
        AVG(sd.ws_net_profit) AS avg_net_profit
    FROM customer_data cd
    JOIN sales_data sd ON cd.c_customer_id = sd.ws_order_number
    GROUP BY cd.full_name, cd.email_lowercase, cd.ca_city, cd.ca_state
)
SELECT 
    city, 
    state, 
    COUNT(*) AS customer_count, 
    SUM(total_sales) AS total_sales,
    AVG(avg_net_profit) AS avg_profit_per_customer
FROM sales_summary
GROUP BY city, state
ORDER BY total_sales DESC
FETCH FIRST 10 ROWS ONLY;
