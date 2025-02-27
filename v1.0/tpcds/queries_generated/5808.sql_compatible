
WITH SalesData AS (
    SELECT 
        ws.sold_date_sk,
        ws.ship_date_sk,
        ws.item_sk,
        ws.bill_customer_sk,
        ws.quantity,
        ws.ext_sales_price,
        ws.ext_discount_amt,
        ws.net_profit,
        cd.gender,
        cd.education_status,
        ca.city,
        ca.state,
        DATE_TRUNC('month', d.d_date) AS sales_month
    FROM web_sales AS ws
    JOIN customer AS c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim AS d ON ws.sold_date_sk = d.d_date_sk
    WHERE ws.sold_date_sk BETWEEN 2458849 AND 2458920
),
SalesSummary AS (
    SELECT
        sales_month,
        gender,
        education_status,
        city,
        state,
        SUM(quantity) AS total_quantity,
        SUM(ext_sales_price) AS total_sales,
        SUM(ext_discount_amt) AS total_discounts,
        SUM(net_profit) AS total_profit
    FROM SalesData
    GROUP BY sales_month, gender, education_status, city, state
)
SELECT 
    sales_month,
    gender,
    education_status,
    city,
    state,
    total_quantity,
    total_sales,
    total_discounts,
    total_profit,
    RANK() OVER (PARTITION BY sales_month ORDER BY total_profit DESC) AS profit_rank
FROM SalesSummary
WHERE total_profit > 0
ORDER BY sales_month, profit_rank;
