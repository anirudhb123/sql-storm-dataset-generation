
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_month BETWEEN 1 AND 6
        AND (c.c_last_name IS NOT NULL OR c.c_preferred_cust_flag = 'Y')
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS ext_sales_price,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10.00
        AND i.i_container NOT IN ('BOX', 'BAG')
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    r.web_site_id,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(s.ext_sales_price, 0) AS ext_sales_price,
    RANK() OVER (ORDER BY COALESCE(r.total_sales, 0) DESC) AS site_sales_rank,
    CASE 
        WHEN COALESCE(r.total_sales, 0) > 100000 THEN 'High Seller'
        WHEN COALESCE(r.total_sales, 0) BETWEEN 50000 AND 100000 THEN 'Medium Seller'
        ELSE 'Low Seller'
    END AS seller_category,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk) 
     FROM web_sales 
     WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_week_seq = (SELECT MAX(d_week_seq) FROM date_dim WHERE d_current_week = 'Y'))) AS current_week_customers
FROM 
    RankedSales r
LEFT JOIN 
    SalesDetails s ON r.sales_rank = 1
WHERE 
    (s.order_count > 10 OR s.ext_sales_price IS NOT NULL)
ORDER BY 
    site_sales_rank ASC NULLS LAST;
