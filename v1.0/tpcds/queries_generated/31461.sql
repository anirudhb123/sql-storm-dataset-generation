
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales) -- Latest sales date
    GROUP BY 
        ws.ws_item_sk
),
ReturningCustomerSales AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns sr
    WHERE 
        sr.sr_customer_sk IN (SELECT c_customer_sk FROM CustomerHierarchy)
    GROUP BY 
        sr.sr_item_sk
),
FinalizedSales AS (
    SELECT 
        id.i_item_id,
        id.i_item_desc,
        COALESCE(sd.total_quantity, 0) AS total_sold,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(rcs.total_returns, 0) AS total_returns,
        COALESCE(rcs.total_returned_amt, 0) AS total_returned_amt
    FROM 
        item id
    LEFT JOIN 
        SalesData sd ON id.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        ReturningCustomerSales rcs ON id.i_item_sk = rcs.sr_item_sk 
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.total_sold,
    f.total_profit,
    f.total_returns,
    f.total_returned_amt,
    (CASE 
        WHEN f.total_profit > 0 THEN 'Profitable'
        WHEN f.total_profit < 0 THEN 'Loss'
        ELSE 'Break-even'
     END) AS profit_status
FROM 
    FinalizedSales f
WHERE 
    (f.total_sold > 100 OR f.total_returns > 10) -- Only include items with significant sales or returns
ORDER BY 
    f.total_profit DESC;
