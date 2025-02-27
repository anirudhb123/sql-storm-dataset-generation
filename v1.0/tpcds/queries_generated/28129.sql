
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating,
        ca.ca_city, 
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_net_paid, 
        TIMESTAMP(DATE(d.d_date), TIME(t.t_time)) AS sale_timestamp,
        ci.full_name, 
        ci.ca_city
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
),
RankedSales AS (
    SELECT 
        sale_timestamp,
        full_name, 
        ca_city, 
        SUM(ws_sales_price) OVER (PARTITION BY ca_city ORDER BY sale_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
        RANK() OVER (PARTITION BY ca_city ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM SalesData
)
SELECT 
    ca_city, 
    full_name, 
    sales_rank, 
    cumulative_sales
FROM RankedSales
WHERE sales_rank <= 10
ORDER BY ca_city, sales_rank;
