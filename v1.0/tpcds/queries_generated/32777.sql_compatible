
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_ticket_number,
        1 AS return_level
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    UNION ALL
    SELECT 
        sr.returned_date_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.ticket_number,
        cr.return_level + 1
    FROM 
        store_returns sr
    JOIN 
        CustomerReturns cr ON sr.ticket_number = cr.ticket_number
    WHERE 
        cr.return_level < 5
),
SalesData AS (
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(*) AS total_transactions,
        AVG(ws.net_profit) AS avg_profit
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws.sold_date_sk, ws.item_sk
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(SUM(cr.return_quantity), 0) AS total_returns,
        COALESCE(SUM(cr.return_amt), 0) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
FinalReport AS (
    SELECT 
        cm.c_customer_sk,
        cm.c_first_name,
        cm.c_last_name,
        cm.cd_gender,
        sm.sm_carrier,
        sd.total_sales,
        sd.total_transactions,
        sd.avg_profit,
        cm.total_returns,
        cm.total_return_amt
    FROM 
        CustomerMetrics cm
    JOIN 
        SalesData sd ON cm.c_customer_sk = sd.item_sk
    JOIN 
        store s ON sd.item_sk = s.s_store_sk
    LEFT JOIN 
        ship_mode sm ON s.s_store_sk = sm.sm_ship_mode_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    FinalReport
ORDER BY 
    total_sales DESC, total_returns DESC;
