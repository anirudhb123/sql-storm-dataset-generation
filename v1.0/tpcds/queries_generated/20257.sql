
WITH RankedReturns AS (
    SELECT 
        cr.refunded_customer_sk,
        cr.returning_customer_sk,
        cr.return_quantity,
        cr_return_amount,
        cr_return_tax,
        ROW_NUMBER() OVER (PARTITION BY cr.refunded_customer_sk ORDER BY cr.returning_customer_sk DESC) AS rn
    FROM 
        catalog_returns cr
    WHERE 
        cr_return_quantity > 0 AND cr_return_amount IS NOT NULL
), 
HighValueReturns AS (
    SELECT 
        r.refunded_customer_sk,
        SUM(r.return_quantity) AS total_returned_qty,
        SUM(r.cr_return_amount) AS total_refund
    FROM 
        RankedReturns r
    WHERE 
        r.rn = 1
    GROUP BY 
        r.refunded_customer_sk
    HAVING 
        SUM(r.return_quantity) > 10 AND SUM(r.cr_return_amount) > 100
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        d.d_date,
        c.c_first_name,
        c.c_last_name,
        d.d_month_seq,
        d.d_year
    FROM 
        customer c
    JOIN 
        date_dim d ON d.d_date_sk = c.c_first_sales_date_sk 
    WHERE 
        c.c_birth_year IS NOT NULL AND 
        c.c_preferred_cust_flag = 'Y'
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
TotalSales AS (
    SELECT 
        ss.ss_sold_date_sk, 
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_sold_date_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    COALESCE(hv.total_returned_qty, 0) AS return_quantity,
    COALESCE(hv.total_refund, 0) AS total_refund_value,
    COALESCE(sd.total_net_profit, 0) AS web_total_net_profit,
    ts.total_store_profit,
    ts.total_store_quantity,
    CASE 
        WHEN hv.total_returned_qty IS NOT NULL AND sd.total_net_profit IS NOT NULL 
        THEN ROUND((hv.total_refund / sd.total_net_profit), 2) 
        ELSE NULL 
    END AS refund_to_net_profit_ratio
FROM 
    CustomerInfo ci
LEFT JOIN 
    HighValueReturns hv ON ci.c_customer_id = hv.refunded_customer_sk
LEFT JOIN 
    SalesData sd ON ci.c_first_sales_date_sk = sd.ws_sold_date_sk
JOIN 
    TotalSales ts ON ci.c_first_sales_date_sk = ts.ss_sold_date_sk
WHERE 
    (ci.d_month_seq < 12 OR ci.d_year = 2023)
ORDER BY 
    total_refund_value DESC, 
    ci.c_last_name, 
    ci.c_first_name;
