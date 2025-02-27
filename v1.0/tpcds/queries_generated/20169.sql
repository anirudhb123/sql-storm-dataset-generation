
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > (
        SELECT AVG(i2.i_current_price) 
        FROM item i2 
        WHERE i2.i_manufact_id IS NOT NULL
    )
    GROUP BY ws.ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_quantity, 
        rs.total_net_profit
    FROM RankedSales rs
    WHERE rs.rank <= 5
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
ReturnsAnalysis AS (
    SELECT 
        ts.ws_item_sk, 
        ts.total_quantity,
        ts.total_net_profit,
        COALESCE(tr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(tr.total_returned_amt, 0) AS total_returned_amt,
        CASE
            WHEN COALESCE(tr.total_returned_quantity, 0) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM TopSales ts
    LEFT JOIN TotalReturns tr ON ts.ws_item_sk = tr.sr_item_sk
),
SalesWithRegions AS (
    SELECT 
        ra.*, 
        ca.ca_state,
        CASE 
            WHEN ca.ca_state IN ('CA', 'NY', 'TX') THEN 'High Sales Region'
            ELSE 'Other'
        END AS region_category
    FROM ReturnsAnalysis ra
    JOIN customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ra.ws_item_sk LIMIT 1)
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    swr.ws_item_sk, 
    swr.total_quantity,
    swr.total_net_profit,
    swr.total_returned_quantity,
    swr.total_returned_amt,
    swr.return_status,
    swr.region_category
FROM SalesWithRegions swr
WHERE (swr.total_net_profit / NULLIF(swr.total_quantity, 0)) > 5
AND swr.region_category = 'High Sales Region'
ORDER BY swr.total_net_profit DESC
LIMIT 10;
