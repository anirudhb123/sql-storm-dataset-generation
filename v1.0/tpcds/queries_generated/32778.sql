
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_order_number,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_quantity > 10
    UNION ALL
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        ws.quantity + c.quantity,
        ws.sales_price,
        ws.order_number,
        c.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesCTE c ON ws.ws_order_number = c.ws_order_number
    WHERE 
        c.level < 3 AND ws.quantity <= 20
)
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(s.ws_sales_price) AS total_revenue,
    COUNT(DISTINCT s.ws_order_number) AS order_count,
    CASE 
        WHEN SUM(s.ws_sales_price) IS NOT NULL THEN 
            AVG(SUM(s.ws_sales_price)) OVER ()
        ELSE 
            0 
    END AS avg_revenue_per_order
FROM 
    SalesCTE s
JOIN 
    customer c ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name
HAVING 
    total_quantity_sold > 50
ORDER BY 
    total_revenue DESC
LIMIT 10;
