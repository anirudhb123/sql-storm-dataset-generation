
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
),
AggregatedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023
        )
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(RR.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(AS.total_net_profit, 0) AS total_net_profit,
    COALESCE(AS.total_quantity_sold, 0) AS total_quantity_sold,
    CASE 
        WHEN COALESCE(AS.total_quantity_sold, 0) = 0 
        THEN 0 
        ELSE (COALESCE(RR.total_return_quantity, 0) * 100.0) / COALESCE(AS.total_quantity_sold, 1) 
    END AS return_percentage
FROM 
    item i
LEFT JOIN 
    (SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_return_quantity 
     FROM 
        RankedReturns 
     WHERE 
        return_rank = 1 
     GROUP BY 
        sr_item_sk) RR ON i.i_item_sk = RR.sr_item_sk
LEFT JOIN 
    AggregatedSales AS ON i.i_item_sk = AS.ws_item_sk
WHERE 
    i.i_rec_start_date <= CURRENT_DATE 
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CURRENT_DATE)
ORDER BY 
    return_percentage DESC
LIMIT 10;
