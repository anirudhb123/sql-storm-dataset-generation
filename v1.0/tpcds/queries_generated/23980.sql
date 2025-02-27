
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_refunded_cash,
        sr_returned_date_sk,
        1 AS level
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0

    UNION ALL

    SELECT 
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        sr.refunded_cash,
        sr.returned_date_sk,
        cr.level + 1
    FROM 
        store_returns sr
    INNER JOIN 
        CustomerReturns cr ON sr.sr_item_sk = cr.sr_item_sk AND cr.level < 5
    WHERE 
        sr.return_quantity > cr.sr_return_quantity
)

SELECT 
    ca.ca_country,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(CASE 
            WHEN cd_cd_gender = 'M' THEN 1 
            ELSE 0 
        END) AS total_males,
    AVG(COALESCE(NULLIF(w.ws_ext_discount_amt, 0), 1)) AS avg_discount,
    DENSE_RANK() OVER (PARTITION BY ca.ca_country ORDER BY AVG(COALESCE(NULLIF(w.ws_ext_sales_price, 0), 1))) DESC AS country_rank,
    COALESCE(MAX(CASE 
                    WHEN cr.sr_return_quantity IS NOT NULL THEN cr.sr_return_quantity 
                    ELSE 0 
                 END), 0) AS max_return_quantity
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns cr ON w.ws_item_sk = cr.sr_item_sk
LEFT JOIN 
    date_dim dd ON cr.sr_returned_date_sk = dd.d_date_sk
WHERE 
    ca.ca_state IS NOT NULL
    AND dd.d_current_year = 2023
GROUP BY 
    ca.ca_country
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 100
ORDER BY 
    country_rank
WITH ROLLUP;
