
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
detailed_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        i.i_item_desc,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        DATE_FORMAT(STR_TO_DATE(CONCAT(d.d_year, '-', d.d_month_seq, '-', d.d_dom), '%Y-%m-%d'), '%Y-%m-%d') AS sales_date,
        cd.full_name,
        cd.ca_city,
        cd.ca_state
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_details cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
)
SELECT
    dd.sales_date,
    dd.ca_city,
    dd.ca_state,
    COUNT(dd.ws_order_number) AS total_orders,
    SUM(dd.ws_net_paid) AS total_revenue,
    AVG(dd.ws_net_profit) AS avg_net_profit
FROM detailed_sales dd
GROUP BY dd.sales_date, dd.ca_city, dd.ca_state
ORDER BY dd.sales_date, total_revenue DESC
LIMIT 100;
