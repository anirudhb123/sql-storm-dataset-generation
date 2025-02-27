
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        i.i_category,
        i.i_brand,
        d.d_year,
        c.cd_gender,
        c.cd_marital_status
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2018 AND 2022
),
aggregated_sales AS (
    SELECT 
        d_year,
        i_category,
        i_brand,
        cd_gender,
        cd_marital_status,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        AVG(ws_sales_price) AS avg_price,
        COUNT(*) AS total_transactions
    FROM sales_data
    GROUP BY d_year, i_category, i_brand, cd_gender, cd_marital_status
)
SELECT 
    d_year,
    i_category,
    i_brand,
    cd_gender,
    cd_marital_status,
    total_sales,
    avg_price,
    total_transactions,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM aggregated_sales
WHERE total_transactions > 100
ORDER BY d_year, sales_rank;
