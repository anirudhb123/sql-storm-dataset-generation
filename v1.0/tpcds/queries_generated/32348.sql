
WITH RECURSIVE customer_sales_cte AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    c.first_name,
    c.last_name,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.order_count, 0) AS order_count,
    CASE 
        WHEN cs.rank IS NULL THEN 'New Customer'
        WHEN cs.total_sales > 1000 THEN 'Best Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    (SELECT DISTINCT c.c_first_name AS first_name, c.c_last_name AS last_name
     FROM customer c) AS c
LEFT JOIN 
    customer_sales_cte cs ON c.c_first_name = cs.c_first_name AND c.c_last_name = cs.c_last_name
WHERE 
    cs.total_sales < (
        SELECT AVG(total_sales)
        FROM customer_sales_cte
    )
ORDER BY 
    total_sales DESC;

WITH item_sales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(s.total_sales, 0) AS total_sales,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No Sales'
        WHEN s.total_sales > 5000 THEN 'High Seller'
        ELSE 'Regular Seller'
    END AS sales_category
FROM 
    item i
LEFT JOIN 
    item_sales s ON i.i_item_id = s.i_item_id
WHERE 
    i.i_current_price IS NOT NULL
AND 
    i.i_rec_end_date IS NULL
ORDER BY 
    total_sales DESC;

SELECT 
    ca.ca_state,
    COUNT(DISTINCT s.s_store_sk) AS store_count,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_net_paid) AS avg_net_paid
FROM 
    store s
JOIN 
    store_sales ss ON s.s_store_sk = ss.ss_store_sk
JOIN 
    customer_address ca ON s.s_store_id = ca.ca_address_id
WHERE 
    ca.ca_country = 'USA'
GROUP BY 
    ca.ca_state
HAVING 
    SUM(ss.ss_net_profit) > (
        SELECT AVG(total_net_profit) 
        FROM (
            SELECT SUM(ss_net_profit) AS total_net_profit
            FROM store_sales
            GROUP BY ss_store_sk
        ) AS net_profit_summary
    )
ORDER BY 
    total_net_profit DESC;
