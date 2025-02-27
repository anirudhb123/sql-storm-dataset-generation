
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_id,
        s_store_name,
        s_number_employees,
        s_geo_class,
        NULL AS parent_store_sk,
        0 AS level
    FROM 
        store
    UNION ALL
    SELECT 
        s.store_sk,
        s.store_id,
        s.store_name,
        s.number_employees,
        s.geo_class,
        sh.s_store_sk AS parent_store_sk,
        sh.level + 1
    FROM 
        store s
    JOIN sales_hierarchy sh ON s.parent_store_sk = sh.s_store_sk
),
total_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN customer c ON ws.ws_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS average_sales
    FROM 
        total_sales
),
discounted_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        CASE 
            WHEN ws.ws_ext_discount_amt > 0 THEN ws.ws_ext_sales_price - ws.ws_ext_discount_amt
            ELSE ws.ws_ext_sales_price
        END AS net_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(total_sales) FROM total_sales)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS city_rank,
    CASE 
        WHEN SUM(ws.ws_net_paid_inc_tax) IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    discounted_sales d ON ws.ws_order_number = d.ws_order_number
WHERE 
    ca.ca_state = 'CA' 
    AND EXISTS (
        SELECT 1
        FROM avg_sales
        WHERE 
            (SELECT AVG(total_sales) FROM total_sales) < (SELECT SUM(ws.ws_sales_price) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
    )
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city
ORDER BY 
    total_net_paid DESC, order_count ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
