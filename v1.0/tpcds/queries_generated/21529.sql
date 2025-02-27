
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_quantity DESC) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(cr.refunded_customer_sk) AS total_refunds,
        AVG(cr_return_quantity) AS avg_refund_qty,
        SUM(CASE WHEN cr_refunded_customer_sk IS NULL THEN 1 ELSE 0 END) AS null_refunds
    FROM 
        customer c
    LEFT JOIN 
        store_returns cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
WebSalesDetails AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL 
    GROUP BY 
        ws.web_site_sk, ws.ws_ship_date_sk, ws.ws_item_sk
),
TotalSales AS (
    SELECT 
        SUM(cs.cs_net_paid) AS overall_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_ext_discount_amt IS NOT NULL
)
SELECT 
    c.c_customer_sk,
    cs.total_refunds,
    cs.avg_refund_qty,
    cs.null_refunds,
    COALESCE((SELECT COUNT(*) FROM RankedReturns rr WHERE rr.sr_customer_sk = c.c_customer_sk AND rr.rnk <= 2), 0) AS top_returns,
    w.total_sales,
    w.total_profit,
    ts.overall_sales,
    ts.order_count
FROM 
    customer c
JOIN 
    CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    WebSalesDetails w ON w.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk) 
CROSS JOIN 
    TotalSales ts
WHERE 
    c.c_birth_year IS NOT NULL 
    AND (c.c_birth_month > 0 OR c.c_birth_month IS NULL)
ORDER BY 
    cs.total_refunds DESC, w.total_sales DESC;
