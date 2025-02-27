
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.store_sk,
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        COALESCE(NULLIF(sr.refunded_cash, 0), sr.return_amt) AS net_refund,
        ROW_NUMBER() OVER (PARTITION BY sr.store_sk ORDER BY sr.returned_date_sk DESC) AS rnk
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
    AND 
        sr.return_amt IS NOT NULL
), WebReturns AS (
    SELECT 
        wr.returned_date_sk,
        wr.web_page_sk,
        wr.item_sk,
        wr.return_quantity,
        wr.return_amt,
        wr.return_tax,
        COALESCE(NULLIF(wr.refunded_cash, 0), wr.return_amt) AS net_refund,
        ROW_NUMBER() OVER (PARTITION BY wr.web_page_sk ORDER BY wr.returned_date_sk DESC) AS rnk
    FROM 
        web_returns wr
    WHERE 
        wr.return_quantity > 0
    AND 
        wr.return_amt IS NOT NULL
), CombinedReturns AS (
    SELECT 
        cr.returned_date_sk,
        cr.store_sk,
        cr.item_sk,
        cr.return_quantity,
        cr.return_amt,
        cr.return_tax,
        cr.net_refund
    FROM 
        CustomerReturns cr
    WHERE 
        cr.rnk = 1
    
    UNION ALL

    SELECT 
        wr.returned_date_sk,
        NULL AS store_sk,
        wr.item_sk,
        wr.return_quantity,
        wr.return_amt,
        wr.return_tax,
        wr.net_refund
    FROM 
        WebReturns wr
    WHERE 
        wr.rnk = 1
)
SELECT 
    ca.city,
    COUNT(DISTINCT c.customer_sk) AS unique_customers,
    SUM(CASE WHEN cr.store_sk IS NOT NULL THEN cr.net_refund ELSE 0 END) AS total_store_refunds,
    SUM(CASE WHEN cr.store_sk IS NULL THEN cr.net_refund ELSE 0 END) AS total_web_refunds,
    AVG(NULLIF(cr.return_amt, 0)) AS avg_return_amount,
    STRING_AGG(DISTINCT i.item_desc, ', ') AS returned_items,
    DATEDIFF(day, MIN(cr.returned_date_sk), MAX(cr.returned_date_sk)) AS return_duration_days
FROM 
    CombinedReturns cr
JOIN 
    customer c ON c.customer_sk = cr.store_sk OR c.customer_sk = cr.returned_date_sk
JOIN 
    inventory inv ON inv.item_sk = cr.item_sk
JOIN 
    customer_address ca ON ca.address_sk = c.current_addr_sk
LEFT JOIN 
    item i ON i.item_sk = cr.item_sk
WHERE 
    (cr.return_quantity IS NOT NULL OR cr.return_amt IS NOT NULL)
    AND (cr.returned_date_sk BETWEEN 20230101 AND 20231231)
GROUP BY 
    ca.city
HAVING 
    COUNT(DISTINCT cr.item_sk) > 5
ORDER BY 
    total_store_refunds DESC, unique_customers DESC
LIMIT 100;
