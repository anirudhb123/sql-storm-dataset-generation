
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
), 
ItemSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sold, 
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
), 
SalesAnalysis AS (
    SELECT 
        ir.ws_item_sk,
        COALESCE(ir.total_sold, 0) AS total_sold,
        COALESCE(ir.total_net_paid, 0) AS total_net_paid,
        COALESCE(rr.total_returned, 0) AS total_returned,
        CASE 
            WHEN COALESCE(ir.total_sold, 0) = 0 THEN NULL 
            ELSE (COALESCE(rr.total_returned, 0) * 100.0 / COALESCE(ir.total_sold, 0)) 
        END AS return_rate_percentage
    FROM 
        ItemSales ir 
    LEFT JOIN 
        RankedReturns rr ON ir.ws_item_sk = rr.sr_item_sk
), 
ExcessiveReturns AS (
    SELECT 
        sa.ws_item_sk, 
        sa.return_rate_percentage
    FROM 
        SalesAnalysis sa
    WHERE 
        sa.return_rate_percentage > 50
), 
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_id
)

SELECT 
    c.c_customer_id,
    CASE 
        WHEN er.return_rate_percentage IS NOT NULL THEN 'High Return Rate'
        ELSE 'Normal'
    END AS return_category,
    cs.total_spent
FROM 
    customer c
LEFT JOIN 
    ExcessiveReturns er ON er.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
JOIN 
    CustomerSales cs ON cs.c_customer_id = c.c_customer_id
WHERE 
    (cs.total_spent > 100 OR er.return_rate_percentage IS NOT NULL)
ORDER BY 
    total_spent DESC,
    return_category ASC
LIMIT 10;
