
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_item_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_quantity DESC) AS return_rank
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
HighReturnItems AS (
    SELECT 
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_returns
    FROM RankedReturns rr
    WHERE rr.return_rank <= 3
    GROUP BY rr.sr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM item i
    LEFT JOIN income_band ib ON i.i_current_price BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ws.ws_item_sk
)
SELECT 
    itd.i_item_desc,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(sd.total_sold, 0) AS total_sold,
    COALESCE(sd.total_profit, 0) AS total_profit,
    CASE 
        WHEN COALESCE(sd.total_sold, 0) = 0 THEN 'No Sales'
        WHEN COALESCE(r.total_returns, 0) > 0 THEN 'High Return Rate'
        ELSE 'Normal Performance'
    END AS performance_category
FROM ItemDetails itd
LEFT JOIN HighReturnItems r ON itd.i_item_id = r.sr_item_sk::TEXT
LEFT JOIN SalesData sd ON itd.i_item_id = sd.ws_item_sk::TEXT
ORDER BY total_returns DESC, total_profit DESC
LIMIT 25;
