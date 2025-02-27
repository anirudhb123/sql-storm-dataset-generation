
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        COUNT(sr.ticket_number) AS returns_count,
        SUM(sr.return_quantity) AS total_returned_quantity
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state
),
date_info AS (
    SELECT 
        d.d_date_id,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM date_dim d
    WHERE d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        w.w_warehouse_name,
        w.w_city
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_ship_date_sk IS NOT NULL
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.ca_city,
    ci.ca_state,
    di.d_year,
    di.d_month_seq,
    di.d_day_name,
    SUM(sd.ws_sales_price) AS total_spent,
    ci.returns_count,
    ci.total_returned_quantity
FROM customer_info ci
JOIN sales_data sd ON ci.c_customer_id = sd.ws_bill_customer_sk
JOIN date_info di ON sd.ws_ship_date_sk = di.d_date_id
GROUP BY 
    ci.full_name, 
    ci.cd_gender, 
    ci.ca_city, 
    ci.ca_state, 
    di.d_year, 
    di.d_month_seq, 
    di.d_day_name
ORDER BY 
    total_spent DESC
LIMIT 100;
