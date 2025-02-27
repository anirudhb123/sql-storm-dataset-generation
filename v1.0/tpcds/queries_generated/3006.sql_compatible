
WITH ranked_sales AS (
    SELECT 
        ws.item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        RANK() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 3)
    GROUP BY 
        ws.item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
    AVG(rs.total_quantity_sold) AS avg_quantity_per_customer,
    SUM(rs.total_sales_amount) AS total_sales,
    CASE 
        WHEN AVG(rs.total_sales_amount) IS NULL THEN 'No Sales'
        ELSE 'Sales Available'
    END AS sales_status
FROM 
    customer_address ca
    JOIN customer_info ci ON ca.ca_address_sk = ci.c_customer_sk
    LEFT JOIN ranked_sales rs ON ci.c_customer_sk = rs.item_sk
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT ci.c_customer_sk) > 10 AND 
    SUM(rs.total_sales_amount) > 5000
ORDER BY 
    total_sales DESC;
