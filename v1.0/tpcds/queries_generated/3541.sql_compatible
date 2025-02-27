
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_price,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_order_number) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) OVER (PARTITION BY ws.ws_order_number) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
StoreSales AS (
    SELECT 
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        SUM(ss.ss_sales_price * ss.ss_quantity) AS total_store_sales
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ss.ss_ticket_number, ss.ss_item_sk
)
SELECT 
    rs.ws_order_number,
    rs.ws_item_sk,
    rs.ws_quantity,
    rs.ws_sales_price,
    rs.total_quantity,
    rs.total_sales,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    (rs.total_sales - COALESCE(ss.total_store_sales, 0)) AS online_vs_store_difference
FROM 
    RankedSales rs
LEFT JOIN 
    StoreSales ss ON rs.ws_order_number = ss.ss_ticket_number AND rs.ws_item_sk = ss.ss_item_sk
WHERE 
    rs.rank_price = 1
ORDER BY 
    online_vs_store_difference DESC
LIMIT 100;
