
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(CASE WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity ELSE 0 END), 0) AS total_return_quantity,
        COALESCE(SUM(CASE WHEN sr_return_amt IS NOT NULL THEN sr_return_amt ELSE 0 END), 0) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
PromotionalReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(*) AS total_promo_returns
    FROM 
        catalog_returns cr
    JOIN 
        promotion p ON cr.cr_reason_sk = p.p_promo_sk
    GROUP BY 
        cr_returning_customer_sk
),
ReturnDetails AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amt_inc_tax) AS total_returned_amount,
        LISTAGG(DISTINCT p.p_promo_name || ' (' || p.p_discount_active || ')', ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promotional_discount_info
    FROM 
        catalog_returns cr
    JOIN 
        promotion p ON cr.cr_reason_sk = p.p_promo_sk
    GROUP BY 
        cr.cr_item_sk
),
RankedReturns AS (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.cr_item_sk ORDER BY r.total_returned_amount DESC) AS rank
    FROM 
        ReturnDetails r
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_return_quantity,
    cs.total_return_amount,
    COALESCE(pr.total_promo_returns, 0) AS total_promotional_returns,
    rr.total_returned,
    rr.total_returned_amount,
    rr.promotional_discount_info
FROM 
    customer c
JOIN 
    CustomerReturnStats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    PromotionalReturns pr ON c.c_customer_sk = pr.cr_returning_customer_sk
LEFT JOIN 
    RankedReturns rr ON rr.cr_item_sk = (SELECT MIN(cr_item_sk) FROM RankedReturns) 
WHERE 
    rr.rank = 1 OR rr.rank IS NULL
ORDER BY 
    cs.total_return_amount DESC, c.c_last_name;
