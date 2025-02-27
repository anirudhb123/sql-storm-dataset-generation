
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 1 AS level
    FROM customer
    WHERE c_customer_sk IN (SELECT DISTINCT sr_customer_sk FROM store_returns WHERE sr_return_quantity > 0)
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
), 

SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),

ReturnsData AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns 
    GROUP BY sr_item_sk
),

CombinedData AS (
    SELECT 
        sd.ws_item_sk,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_returned_amount, 0) AS total_returned_amount
    FROM SalesData sd
    FULL OUTER JOIN ReturnsData rd ON sd.ws_item_sk = rd.sr_item_sk
)

SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.level,
    SUM(cd.total_quantity) AS quantity_sold,
    SUM(cd.total_profit) AS profit_generated,
    SUM(cd.total_returns) AS total_returns,
    SUM(cd.total_returned_amount) AS total_returned
FROM CustomerHierarchy cd
JOIN CombinedData cdata ON cd.c_customer_sk IN (
    SELECT ws_bill_customer_sk
    FROM web_sales
    WHERE ws_item_sk IN (SELECT ws_item_sk FROM CombinedData)
)
GROUP BY cd.c_first_name, cd.c_last_name, cd.level
HAVING SUM(cd.total_profit) > 1000
ORDER BY cd.level, profit_generated DESC;
