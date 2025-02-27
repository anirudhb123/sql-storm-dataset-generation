
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_id,
        cd_marital_status,
        cd_gender,
        COUNT(cs_order_number) AS order_count,
        COUNT(DISTINCT ws_web_page_sk) AS web_page_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c_customer_id, cd_marital_status, cd_gender
    HAVING 
        COUNT(cs_order_number) > 10 AND COUNT(DISTINCT ws_web_page_sk) > 5
),
ProductReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_returned_date_sk) AS return_count,
        AVG(sr_return_amt) AS avg_return_amt,
        MAX(sr_return_quantity) AS max_return_quantity
    FROM 
        store_returns 
    WHERE 
        sr_return_quantity IS NOT NULL
    GROUP BY 
        sr_item_sk
),
OuterJoinResults AS (
    SELECT 
        ws.ws_item_sk,
        COALESCE(pr.return_count, 0) AS return_count,
        COALESCE(hv.order_count, 0) AS order_count
    FROM 
        web_sales ws
    LEFT JOIN 
        ProductReturns pr ON ws.ws_item_sk = pr.sr_item_sk
    LEFT JOIN 
        HighValueCustomers hv ON ws.ws_bill_customer_sk = hv.c_customer_id
    WHERE 
        ws.ws_net_profit > (SELECT AVG(ws_net_profit) FROM web_sales) 
        AND (hv.order_count > 0 OR pr.return_count > 0)
)
SELECT 
    p.i_item_id,
    r.return_count,
    r.order_count,
    p.i_current_price,
    CASE 
        WHEN r.return_count > 0 THEN 'High Return'
        WHEN r.order_count > 0 AND p.i_current_price > 50 THEN 'High Value'
        ELSE 'Normal'
    END AS status
FROM 
    item p
JOIN 
    OuterJoinResults r ON p.i_item_sk = r.ws_item_sk
WHERE 
    (p.i_current_price IS NOT NULL AND p.i_current_price > 20)
    AND (r.return_count IS NOT NULL OR r.order_count IS NOT NULL)
ORDER BY 
    p.i_item_id,
    status DESC;
