
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_manager,
        s_rec_start_date,
        s_closed_date_sk,
        1 AS level
    FROM 
        store
    WHERE 
        s_closed_date_sk IS NULL
    UNION ALL
    SELECT 
        s.store_sk,
        s.s_store_name,
        s.s_number_employees,
        s.s_manager,
        s.s_rec_start_date,
        s.s_closed_date_sk,
        sh.level + 1
    FROM 
        store s
    JOIN 
        sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
)
SELECT 
    customer.c_first_name || ' ' || customer.c_last_name AS customer_name,
    sum(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    MAX(ws_net_profit) AS max_profit,
    SUM(CASE WHEN ws_shipping_mode IS NULL THEN 1 ELSE 0 END) AS null_ship_mode_count,
    ROW_NUMBER() OVER (PARTITION BY customer.c_customer_sk ORDER BY sum(ws_ext_sales_price) DESC) as sales_rank
FROM 
    web_sales
JOIN 
    customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
LEFT JOIN 
    ship_mode ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
WHERE 
    (web_sales.ws_sold_date_sk, web_sales.ws_item_sk) IN (
        SELECT cs_sold_date_sk, cs_item_sk 
        FROM catalog_sales
        WHERE cs_quantity > 0
    ) AND 
    customer.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    customer.c_customer_sk, customer.c_first_name, customer.c_last_name
HAVING 
    SUM(ws_ext_sales_price) > 1000 AND 
    total_orders > 5
ORDER BY 
    total_sales DESC
FETCH FIRST 10 ROWS ONLY;
