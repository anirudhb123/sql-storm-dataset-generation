
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        DATE_FORMAT(d.d_date, '%Y-%m') AS sales_month
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
AggregatedSales AS (
    SELECT 
        cs.c_customer_sk,
        SUM(si.ws_sales_price * si.ws_quantity) AS total_spent,
        COUNT(si.ws_item_sk) AS total_items,
        MONTH(d.d_date) AS sales_month
    FROM CustomerInfo cs
    JOIN SalesInfo si ON cs.c_customer_sk = si.ws_bill_customer_sk
    JOIN date_dim d ON si.ws_ship_date_sk = d.d_date_sk
    GROUP BY cs.c_customer_sk, MONTH(d.d_date)
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    as.total_spent,
    as.total_items,
    as.sales_month
FROM CustomerInfo ci
JOIN AggregatedSales as ON ci.c_customer_sk = as.c_customer_sk
WHERE as.total_spent > (SELECT AVG(total_spent) FROM AggregatedSales)
ORDER BY total_spent DESC;
