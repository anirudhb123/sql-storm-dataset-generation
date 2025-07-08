
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_sales_price * ws.ws_quantity) > 1000
    UNION ALL
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_sales * 0.9 AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY sh.total_sales DESC) AS rank
    FROM 
        sales_hierarchy sh
    WHERE 
        sh.rank <= 5
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    LISTAGG(i.i_product_name, ', ') WITHIN GROUP (ORDER BY i.i_product_name ASC) AS products_ordered
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    c.c_birth_year = (SELECT MAX(c2.c_birth_year) FROM customer c2) 
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    net_profit DESC
LIMIT 10
OFFSET 5;
