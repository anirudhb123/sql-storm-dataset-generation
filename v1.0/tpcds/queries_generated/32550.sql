
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, c.c_birth_year

    UNION ALL

    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        total_profit * 1.1 AS total_profit
    FROM 
        SalesHierarchy sh
    JOIN 
        customer c ON c.c_customer_id = sh.c_customer_id
    WHERE 
        c.c_birth_year < sh.c_birth_year
)

SELECT 
    s.c_customer_id,
    s.c_first_name,
    s.c_last_name,
    DENSE_RANK() OVER (ORDER BY SUM(total_profit) DESC) AS rank,
    CASE 
        WHEN SUM(total_profit) IS NULL THEN 'No Profit'
        ELSE CONCAT('Profit: $', FORMAT(SUM(total_profit), 2))
    END AS profit_summary
FROM 
    SalesHierarchy s
GROUP BY 
    s.c_customer_id, s.c_first_name, s.c_last_name
HAVING 
    SUM(total_profit) > 0
ORDER BY 
    rank
LIMIT 10;

WITH ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COALESCE(NULLIF(MAX(ws.ws_ext_discount_amt), 0), NULL) AS max_discount
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        ws.ws_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    is.total_sales,
    CASE WHEN is.max_discount IS NULL THEN 'No Discounts'
         ELSE CONCAT('Max Discount: $', FORMAT(is.max_discount, 2))
    END AS discount_summary
FROM 
    item i 
LEFT JOIN 
    ItemSales is ON i.i_item_sk = is.ws_item_sk
WHERE 
    is.total_sales > 1000
ORDER BY 
    is.total_sales DESC;
