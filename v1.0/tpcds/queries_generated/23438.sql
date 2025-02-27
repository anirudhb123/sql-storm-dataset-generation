
WITH RankedReturns AS (
    SELECT 
        sr_return_customer_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_return_customer_sk ORDER BY sr_return_amt DESC) as rank_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
TopReturns AS (
    SELECT
        rr.sr_return_customer_sk,
        SUM(rr.sr_return_amt) AS total_return_amt
    FROM 
        RankedReturns rr
    WHERE 
        rr.rank_amt <= 5
    GROUP BY 
        rr.sr_return_customer_sk
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    COALESCE(SUM(tr.total_return_amt), 0) AS total_return_amount,
    AVG(sm.sm_carrier) OVER (PARTITION BY ca.ca_state) AS avg_carrier_length,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names,
    CASE WHEN EXTRACT(MONTH FROM CURRENT_DATE) IN (11, 12) 
         THEN 'Holiday Season' 
         ELSE 'Regular Season' 
    END AS season_indicator
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    TopReturns tr ON c.c_customer_sk = tr.sr_return_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    ship_mode sm ON ss.ss_item_sk = sm.sm_ship_mode_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY 
    total_return_amount DESC
LIMIT 10;
