
WITH RECURSIVE sales_data AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
    
    UNION ALL
    
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(cs_order_number) AS total_orders
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_sold_date_sk, cs_item_sk
),
item_summary AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(sd.total_sales, 0) AS total_sales_amount,
        COALESCE(sd.total_orders, 0) AS total_order_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY COALESCE(sd.total_sales, 0) DESC) AS rank
    FROM item i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk OR i.i_item_sk = sd.cs_item_sk
),
address_summary AS (
    SELECT
        ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(COALESCE(sd.total_sales_amount, 0)) AS total_sales_by_state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN item_summary sd ON sd.rank <= 10
    GROUP BY ca_state
)
SELECT
    asu.ca_state,
    asu.total_customers,
    asu.total_sales_by_state,
    (SELECT AVG(total_sales_by_state) FROM address_summary) AS avg_sales_by_state,
    CASE 
        WHEN asu.total_sales_by_state IS NULL THEN 'No Sales'
        WHEN asu.total_sales_by_state > (SELECT AVG(total_sales_by_state) FROM address_summary) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM address_summary asu
ORDER BY asu.total_sales_by_state DESC
LIMIT 10;
