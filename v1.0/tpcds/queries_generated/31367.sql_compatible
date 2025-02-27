
WITH RECURSIVE sales_cte AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    UNION ALL
    SELECT
        s.cs_sold_date_sk,
        s.cs_item_sk,
        s.cs_order_number,
        s.cs_quantity,
        s.cs_sales_price,
        s.cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY s.cs_item_sk ORDER BY s.cs_order_number) AS rn
    FROM catalog_sales s
    INNER JOIN sales_cte cte ON s.cs_item_sk = cte.ws_item_sk
    WHERE s.cs_sold_date_sk <= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state
)
SELECT 
    c.ca_state,
    SUM(s.ws_ext_sales_price) AS total_web_sales,
    SUM(s.cs_ext_sales_price) AS total_catalog_sales,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    AVG(CASE WHEN ci.cd_gender = 'M' THEN s.ws_ext_sales_price END) AS avg_sales_male,
    AVG(CASE WHEN ci.cd_gender = 'F' THEN s.ws_ext_sales_price END) AS avg_sales_female
FROM sales_cte s
JOIN customer_info ci ON ci.c_customer_sk IN (s.ws_bill_customer_sk, s.ws_ship_customer_sk)
LEFT JOIN customer_address c ON c.ca_address_sk = ci.c_customer_sk
WHERE c.ca_state IS NOT NULL
    AND ci.rank <= 5
GROUP BY c.ca_state
ORDER BY total_web_sales DESC, total_catalog_sales DESC;
