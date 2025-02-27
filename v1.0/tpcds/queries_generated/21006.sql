
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),  
ItemStats AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned,
        AVG(sr_return_quantity) AS avg_returned_quantity
    FROM 
        RankedReturns rr
    JOIN 
        store_sales ss ON rr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN 
        item i ON rr.sr_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
    HAVING 
        COUNT(DISTINCT sr_ticket_number) > 5
), 
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_discount_amt) AS total_discount  
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
CombinedData AS (
    SELECT 
        is.i_item_sk,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(is.total_returns, 0) AS total_returns,
        COALESCE(is.avg_returned_quantity, 0) AS avg_returned_quantity,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_discount, 0) AS total_discount,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) = 0 THEN NULL
            ELSE (COALESCE(is.total_returns, 0) / COALESCE(sd.total_sales, 0)) * 100 
        END AS return_rate_percentage
    FROM 
        ItemStats is
    FULL OUTER JOIN 
        SalesData sd ON is.i_item_sk = sd.ws_item_sk
)
SELECT 
    c.c_customer_id,
    cm.i_item_sk,
    cm.total_sales,
    cm.total_returns,
    cm.avg_returned_quantity,
    cm.return_rate_percentage
FROM 
    customer c
JOIN 
    CombinedData cm ON c.c_customer_sk = (
        SELECT DISTINCT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = cm.i_item_sk 
        LIMIT 1
    )
WHERE 
    (c.c_current_cdemo_sk IS NOT NULL OR c.c_current_hdemo_sk IS NOT NULL)
    AND (SELECT COUNT(*) FROM store WHERE s_state = 'CA') > 100
ORDER BY 
    cm.return_rate_percentage DESC NULLS LAST;
