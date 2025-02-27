
WITH RankedReturns AS (
    SELECT 
        sr.returning_customer_sk,
        sr.returned_date_sk,
        sr.returned_time_sk,
        sr.return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr.returning_customer_sk ORDER BY sr.returned_date_sk DESC) AS rn
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > (SELECT AVG(sr2.return_quantity)
                              FROM store_returns sr2
                              WHERE sr2.returning_customer_sk = sr.returning_customer_sk)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        RANK() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY cd.cd_purchase_estimate DESC) AS income_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    rr.returned_date_sk,
    rr.returned_time_sk,
    rr.return_quantity,
    CASE 
        WHEN rr.rn = 1 THEN 'Most Recent Return'
        ELSE 'Previous Return'
    END AS return_status,
    COUNT(DISTINCT ci.c_customer_sk) OVER (PARTITION BY ci.cd_income_band_sk) AS customer_count_in_band
FROM 
    RankedReturns rr
JOIN 
    CustomerInfo ci ON rr.returning_customer_sk = ci.c_customer_sk
WHERE 
    ci.income_rank <= 5 
    AND (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        WHERE cs.cs_ship_customer_sk = rr.returning_customer_sk
        AND cs.cs_order_number IN (
            SELECT ws_order_number 
            FROM web_sales ws 
            WHERE ws.ws_ship_customer_sk = rr.returning_customer_sk
            INTERSECT
            SELECT sr_ticket_number 
            FROM store_returns sr 
            WHERE sr.sr_customer_sk = rr.returning_customer_sk
        )
    )
ORDER BY 
    ci.ca_state, 
    rr.returned_date_sk DESC, 
    rr.return_time_sk ASC;
