
WITH RankedSales AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) AS rank_profit
    FROM web_sales
), TotalReturns AS (
    SELECT
        SUM(sr_return_quantity) AS total_returned_quantity,
        sr_item_sk
    FROM store_returns
    WHERE sr_returned_date_sk = (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_date = CURRENT_DATE
        )
    GROUP BY sr_item_sk
), ItemDetails AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        COALESCE(tr.total_returned_quantity, 0) AS return_qty
    FROM item i
    LEFT JOIN TotalReturns tr ON i.i_item_sk = tr.sr_item_sk
)
SELECT 
    ISNULL(d.d_day_name, 'Unknown Day') AS sale_day,
    id.i_item_id,
    id.i_item_desc,
    SUM(rs.ws_quantity) AS total_quantity_sold,
    SUM(rs.ws_net_profit) AS total_net_profit,
    STRING_AGG(i.ca_city, ', ') AS cities_sold
FROM RankedSales rs
JOIN ItemDetails id ON rs.ws_item_sk = id.i_item_sk
JOIN date_dim d ON d.d_date_sk = rs.ws_sold_date_sk
LEFT JOIN customer_address i ON i.ca_address_sk = (
    SELECT TOP 1 ca.ca_address_sk 
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_customer_sk = rs.ws_bill_customer_sk
    ORDER BY NEWID()
)
WHERE 
    d.d_year = 2023 
    AND id.return_qty < (SELECT AVG(return_qty)
                         FROM ItemDetails)
GROUP BY 
    d.d_day_name, id.i_item_id, id.i_item_desc
HAVING 
    SUM(rs.ws_quantity) > (
        SELECT AVG(ws_quantity)
        FROM RankedSales
        WHERE ws_item_sk = id.i_item_sk
    )
ORDER BY 
    total_net_profit DESC
OPTION (MAXRECURSION 0);
