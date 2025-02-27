
WITH RankedSales AS (
    SELECT 
        customer.c_customer_id, 
        SUM(CASE 
                WHEN ws.ws_sales_price > 50 THEN ws.ws_net_paid 
                ELSE NULL 
            END) AS HighValueSales,
        SUM(CASE 
                WHEN ws.ws_sales_price <= 50 THEN ws.ws_net_paid 
                ELSE NULL 
            END) AS LowValueSales,
        DENSE_RANK() OVER (PARTITION BY customer.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS SalesRank
    FROM 
        web_sales ws
    JOIN 
        customer ON ws.ws_bill_customer_sk = customer.c_customer_sk
    GROUP BY 
        customer.c_customer_id
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_id,
        d.cd_gender,
        MAX(d.cd_purchase_estimate) AS max_purchase_estimate,
        STRING_AGG(DISTINCT d.cd_marital_status) AS marital_statuses
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    GROUP BY 
        c.c_customer_id, d.cd_gender
)
SELECT 
    R.c_customer_id,
    R.HighValueSales,
    R.LowValueSales,
    CD.cd_gender,
    CD.max_purchase_estimate,
    CD.marital_statuses
FROM 
    RankedSales R
JOIN 
    CustomerDemographics CD ON R.c_customer_id = CD.c_customer_id
WHERE 
    R.SalesRank <= 3
    AND (R.HighValueSales IS NOT NULL OR R.LowValueSales IS NOT NULL)
    AND (CD.max_purchase_estimate > (SELECT AVG(max_purchase_estimate) FROM CustomerDemographics))
    AND COALESCE(CD.marital_statuses, '') <> 'Single'
ORDER BY 
    R.HighValueSales DESC,
    R.LowValueSales ASC NULLS LAST
LIMIT 100;
