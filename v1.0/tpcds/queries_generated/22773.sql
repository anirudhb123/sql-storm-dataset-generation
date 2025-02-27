
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS rank_by_amount
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        AVG(sr_return_amt) AS avg_return_amount,
        SUM(CASE WHEN sr_return_amt IS NULL THEN 0 ELSE sr_return_amt END) AS total_returned_amount
    FROM 
        customer c 
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
PromotionStats AS (
    SELECT 
        p.p_promo_sk,
        COUNT(*) AS total_sales,
        SUM(CASE WHEN ws_ext_sales_price IS NULL THEN 0 ELSE ws_ext_sales_price END) AS total_sales_amount
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    ca_city,
    COALESCE(SUM(CASE WHEN cds.total_returns > 5 THEN 1 ELSE 0 END), 0) AS high_return_customers,
    COALESCE(AVG(cs.avg_return_amount), 0) AS avg_return_per_customer,
    COUNT(DISTINCT ps.p_promo_sk) AS active_promotions,
    MAX(rs.rank_by_amount) AS highest_returned_amount
FROM 
    customer_address ca
LEFT JOIN 
    CustomerStats cds ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM customer))
LEFT JOIN 
    PromotionStats ps ON 1=1
LEFT JOIN 
    RankedReturns rs ON 1=1
WHERE 
    ca_state = 'NY'
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT ca.ca_address_sk) > 1
ORDER BY 
    high_return_customers DESC, avg_return_per_customer DESC;
