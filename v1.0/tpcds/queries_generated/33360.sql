
WITH RECURSIVE sales_history AS (
    SELECT 
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS sale_count,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
    HAVING 
        SUM(ss_ext_sales_price) > 1000

    UNION ALL

    SELECT 
        s.ss_item_sk,
        sh.total_sales + SUM(s.ss_ext_sales_price) AS total_sales,
        sh.sale_count + COUNT(s.ss_ticket_number) AS sale_count,
        level + 1
    FROM 
        store_sales s
    JOIN 
        sales_history sh ON s.ss_item_sk = sh.ss_item_sk
    WHERE 
        sh.level < 5
    GROUP BY 
        s.ss_item_sk, sh.total_sales, sh.sale_count, level
)

SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    COUNT(ws.ws_order_number) AS order_count,
    CASE 
        WHEN SUM(ws.ws_net_paid) IS NULL THEN 'No Sales'
        ELSE 'Sales Found'
    END AS sales_status
FROM 
    web_sales ws
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    total_web_sales > 50000
ORDER BY 
    total_web_sales DESC;

SELECT 
    item.i_item_id,
    item.i_product_name,
    COALESCE(sh.total_sales, 0) AS computed_sales
FROM 
    item
LEFT JOIN 
    sales_history sh ON item.i_item_sk = sh.ss_item_sk
WHERE 
    item.i_class = 'Beverages' AND
    (item.i_current_price > 10.00 OR sh.sale_count IS NOT NULL)
UNION
SELECT 
    'Total',
    NULL,
    SUM(COALESCE(sh.total_sales, 0))
FROM 
    sales_history sh;
