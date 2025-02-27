
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
    )
    GROUP BY ws.ws_item_sk, ws.ws_order_number
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_sales
    FROM RankedSales ri
    WHERE ri.sales_rank <= 3
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(r.r_reason_desc, 'No Reason') AS return_reason,
        NULLIF(CAST(i.i_item_desc AS VARCHAR), '') AS sanitized_item_desc
    FROM item i
    LEFT JOIN reason r ON r.r_reason_sk = (SELECT cr_reason_sk
                                            FROM catalog_returns cr
                                            WHERE cr.cr_item_sk = i.i_item_sk
                                            ORDER BY cr.cr_return_amount DESC
                                            LIMIT 1)
)
SELECT 
    d.d_date_id,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(CASE WHEN ws.ws_ship_date_sk IS NULL THEN -1 ELSE 1 END) AS shipping_status,
    STRING_AGG(DISTINCT id.sanitized_item_desc, ', ') AS sold_items
FROM web_sales ws
JOIN TopItems ti ON ws.ws_item_sk = ti.ws_item_sk
JOIN ItemDetails id ON id.i_item_sk = ws.ws_item_sk
JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN customer_address ca ON ca.ca_address_sk = ws.ws_bill_addr_sk
WHERE 
    d.d_year IN (2022, 2023)
    AND (ws.ws_sales_price IS NOT NULL OR ws.ws_net_profit IS NULL)
GROUP BY d.d_date_id 
ORDER BY total_net_profit DESC
LIMIT 10;
