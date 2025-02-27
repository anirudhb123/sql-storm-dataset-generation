
WITH CustomerInfo AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        DATE(dd.d_date) AS sale_date,
        time.t_hour,
        time.t_minute
    FROM
        web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN time_dim time ON ws.ws_sold_time_sk = time.t_time_sk
),
TopCustomers AS (
    SELECT
        ci.full_name,
        ci.ca_city,
        SUM(sd.ws_net_profit) AS total_profit
    FROM
        CustomerInfo ci
    JOIN SalesData sd ON ci.c_customer_id = sd.ws_order_number
    GROUP BY
        ci.full_name, ci.ca_city
    ORDER BY
        total_profit DESC
    LIMIT 10
)
SELECT
    tc.full_name,
    tc.ca_city,
    tc.total_profit,
    CASE
        WHEN tc.total_profit > 1000 THEN 'High Value'
        WHEN tc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    TopCustomers tc;
