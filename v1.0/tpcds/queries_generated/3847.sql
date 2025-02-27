
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10000 AND 20000
),
TotalSales AS (
    SELECT 
        ir.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    JOIN 
        item ir ON ws.ws_item_sk = ir.i_item_sk
    GROUP BY 
        ir.i_item_id
),
TopItems AS (
    SELECT 
        tsl.i_item_id,
        tsl.total_quantity_sold,
        tsl.total_sales_amount,
        ROW_NUMBER() OVER (ORDER BY tsl.total_sales_amount DESC) AS sales_rank
    FROM 
        TotalSales tsl
    WHERE 
        tsl.total_quantity_sold > ALL (SELECT AVG(total_quantity_sold) FROM TotalSales)
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws.ws_quantity) AS total_items_sold,
    MAX(ws.ws_sales_price) AS max_sales_price,
    COALESCE(SUM(CASE WHEN sr.returned_date_sk IS NOT NULL THEN sr.return_quantity ELSE 0 END), 0) AS total_returns
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_returns sr ON ws.ws_order_number = sr.sr_ticket_number
JOIN 
    TopItems ti ON ws.ws_item_sk = ti.i_item_id
WHERE 
    ca.ca_city IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    total_items_sold DESC
LIMIT 50;
