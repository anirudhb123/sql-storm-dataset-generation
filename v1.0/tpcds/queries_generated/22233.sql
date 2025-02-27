
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
),
CustomerReturns AS (
    SELECT 
        cr.return_qty,
        cr.return_amt,
        cr.return_time_sk,
        cr.returning_customer_sk,
        r_reason.r_reason_desc
    FROM 
        catalog_returns cr
    LEFT JOIN 
        reason r_reason ON cr.cr_reason_sk = r_reason.r_reason_sk
    WHERE 
        cr.return_qty IS NOT NULL
),
StoreProfit AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        MAX(ws.ws_sales_price - ss.ss_sales_price) AS price_diff
    FROM 
        store_sales ss
    JOIN 
        web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND ss.ss_ticket_number = ws.ws_order_number
    GROUP BY 
        ss.ss_store_sk
),
CustomerCounts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_amt) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
    COALESCE(cc.total_returns, 0) AS total_returns,
    COALESCE(cc.total_return_amt, 0) AS total_return_amt,
    COUNT(DISTINCT r.returning_customer_sk) AS unique_return_reasons,
    SUM(sp.total_profit) AS profit_by_store,
    CASE 
        WHEN SUM(sp.total_profit) > 1000 THEN 'High'
        WHEN SUM(sp.total_profit) BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM 
    customer c
LEFT JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
LEFT JOIN 
    CustomerCounts cc ON c.c_customer_sk = cc.c_customer_sk
LEFT JOIN 
    StoreProfit sp ON sp.ss_store_sk = (SELECT TOP 1 s_store_sk FROM store WHERE s_company_id IS NOT NULL)
LEFT JOIN 
    CustomerReturns r ON r.returning_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_year IS NOT NULL
GROUP BY 
    c.c_customer_id, cc.total_returns, cc.total_return_amt
HAVING 
    COUNT(DISTINCT s.ss_ticket_number) > 5 AND (COALESCE(cc.total_returns, 0) < 2 OR COALESCE(cc.total_return_amt, 0) < 100)
ORDER BY 
    profit_category DESC, total_sales DESC;
