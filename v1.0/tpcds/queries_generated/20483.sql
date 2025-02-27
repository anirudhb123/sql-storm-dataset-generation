
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
HighProfitItems AS (
    SELECT
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_quantity,
        r.ws_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.profit_rank = 1
        AND r.ws_net_profit IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr.returning_customer_sk,
        sr.return_quantity,
        sr.return_amt,
        SUM(COALESCE(sr.return_quantity, 0)) OVER (PARTITION BY sr.returning_customer_sk) AS total_returned_quantity
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date_sk IS NOT NULL
),
FinalResults AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(hp.ws_item_sk, 0) AS item_sk,
        SUM(hp.ws_net_profit) AS total_profit,
        SUM(COALESCE(cr.total_returned_quantity, 0)) AS total_returns,
        (SUM(hp.ws_net_profit) - SUM(COALESCE(cr.total_returned_quantity, 0))) AS net_profit_after_returns
    FROM 
        customer c
    LEFT JOIN HighProfitItems hp ON c.c_customer_sk = hp.ws_order_number
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, hp.ws_item_sk
    HAVING 
        net_profit_after_returns > 10000 OR (total_returns > 10 AND total_profit IS NULL)
)
SELECT 
    fr.c_customer_id,
    fr.c_first_name,
    fr.c_last_name,
    fr.item_sk,
    CASE 
        WHEN fr.total_profit > 5000 THEN 'High Profit'
        WHEN fr.total_profit > 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    fr.net_profit_after_returns
FROM 
    FinalResults fr
WHERE 
    fr.net_profit_after_returns IS NOT NULL 
    AND EXISTS (
        SELECT 1 
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = c.c_current_cdemo_sk 
        AND cd.cd_gender = 'F'
    )
    OR fr.total_returns > 5 
ORDER BY 
    fr.net_profit_after_returns DESC, fr.c_last_name ASC;
