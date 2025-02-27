
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr_returning_customer_sk,
        sr_return_time_sk,
        DENSE_RANK() OVER (PARTITION BY sr_returning_customer_sk ORDER BY sr_return_time_sk DESC) AS return_rank
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
),
CombinedSales AS (
    SELECT 
        rs.ws_order_number,
        COUNT(DISTINCT rs.ws_item_sk) AS total_items,
        SUM(rs.ws_net_paid) AS total_net_paid,
        COALESCE(SUM(cr.sr_return_amt), 0) AS total_returned_amt
    FROM RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.ws_order_number = cr.sr_returning_customer_sk AND cr.return_rank = 1
    GROUP BY rs.ws_order_number
)
SELECT 
    cs.ws_order_number,
    cs.total_items,
    cs.total_net_paid,
    cs.total_returned_amt,
    CASE 
        WHEN cs.total_net_paid > 1000 THEN 'High Value'
        WHEN cs.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category,
    COUNT(DISTINCT i.i_item_id) AS unique_items_sold,
    MAX(i.i_current_price) AS max_item_price
FROM CombinedSales cs
JOIN web_sales ws ON cs.ws_order_number = ws.ws_order_number
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_rec_start_date <= (SELECT MAX(d.d_date) FROM date_dim d WHERE d.d_year = 2023) 
AND (i.i_current_price IS NOT NULL OR i.i_current_price < 0) 
GROUP BY cs.ws_order_number, cs.total_items, cs.total_net_paid, cs.total_returned_amt
HAVING SUM(ws.ws_quantity) FILTER (WHERE ws.ws_ship_date_sk IS NOT NULL) < 100
ORDER BY cs.total_net_paid DESC
LIMIT 100;
