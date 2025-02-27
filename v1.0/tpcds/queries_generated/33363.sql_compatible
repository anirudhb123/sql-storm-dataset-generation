
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i_item_sk, 
        i_item_desc,
        i_brand,
        0 AS level
    FROM 
        item
    WHERE 
        i_item_sk IS NOT NULL

    UNION ALL

    SELECT 
        ih.i_item_sk,
        CONCAT('Sub-', ih.i_item_desc),
        ih.i_brand,
        ih.level + 1
    FROM 
        ItemHierarchy ih
    JOIN 
        item i ON i.i_item_sk = ih.i_item_sk + 1
    WHERE 
        ih.level < 3
),

SalesSummary AS (
    SELECT 
        b.warehouse_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY b.warehouse_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse b ON ws.ws_warehouse_sk = b.warehouse_sk
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_dow = 6) 
    GROUP BY 
        b.warehouse_sk
),

CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned,
        COUNT(*) AS return_count,
        COALESCE(
            SUM(sr_return_amt_inc_tax) / NULLIF(SUM(ws_ext_sales_price), 0),
            0
        ) AS return_rate
    FROM 
        store_returns sr
    LEFT JOIN 
        store_sales ss ON sr.sr_item_sk = ss.ss_item_sk 
    WHERE 
        sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr_customer_sk
)

SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_spent,
    cr.total_returned,
    cr.return_count,
    cr.return_rate,
    sh.total_sales AS warehouse_sales
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
JOIN 
    SalesSummary sh ON c.c_current_addr_sk = sh.warehouse_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_last_name LIKE '%' || 'Smith' || '%')
GROUP BY 
    c.c_customer_id, cr.total_returned, cr.return_count, cr.return_rate, sh.total_sales
HAVING 
    SUM(ss.ss_sales_price) > 100
ORDER BY 
    total_spent DESC
LIMIT 50;
