
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        SalesData.total_quantity,
        SalesData.total_profit
    FROM 
        SalesData
    JOIN 
        item ON SalesData.ws_item_sk = item.i_item_sk
    WHERE 
        SalesData.rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
ReturnAnalytics AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value,
        COALESCE(cr.total_return_value, 0) / NULLIF(SUM(ws.ws_net_profit), 0) AS return_ratio
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cr.total_returns, cr.total_return_value
),
FinalReport AS (
    SELECT 
        tsi.i_item_id,
        tsi.i_item_desc,
        tsi.total_quantity,
        tsi.total_profit,
        ra.c_customer_id,
        ra.c_first_name,
        ra.c_last_name,
        ra.total_returns,
        ra.return_ratio
    FROM 
        TopSellingItems tsi
    JOIN 
        ReturnAnalytics ra ON tsi.total_profit > 1000
)
SELECT 
    fr.i_item_id,
    fr.i_item_desc,
    fr.total_quantity,
    fr.total_profit,
    fr.c_customer_id,
    fr.c_first_name,
    fr.c_last_name,
    fr.total_returns,
    CASE 
        WHEN fr.return_ratio IS NULL THEN 'No Sales' 
        ELSE CAST(fr.return_ratio AS VARCHAR(10)) 
    END AS return_ratio
FROM 
    FinalReport fr
ORDER BY 
    fr.total_profit DESC, 
    fr.return_ratio DESC;
