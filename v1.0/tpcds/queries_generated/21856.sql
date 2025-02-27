
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_quantity) DESC) AS rank_by_quantity
    FROM 
        web_sales ws
    INNER JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_zip IS NOT NULL
    GROUP BY 
        ws.web_site_id
),
IncomeStats AS (
    SELECT 
        cd.cd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_income_band_sk
),
ReturnMetrics AS (
    SELECT 
        sr.return_store_sk,
        SUM(sr.return_quantity) AS total_return_quantity,
        AVG(sr.return_amount) AS avg_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.return_store_sk
)
SELECT 
    COALESCE(rw.web_site_id, 'No Sales') AS website,
    ISNULL(is.customer_count, 0) AS total_customers,
    ISNULL(is.avg_purchase_estimate, 0) AS average_purchase_by_income,
    COALESCE(rm.total_return_quantity, 0) AS total_returns,
    COALESCE(rm.avg_return_amount, 0) AS average_return_value
FROM 
    RankedSales rw
FULL OUTER JOIN 
    IncomeStats is ON rw.web_site_id = is.cd_income_band_sk
FULL OUTER JOIN 
    ReturnMetrics rm ON rm.return_store_sk = is.cd_income_band_sk
WHERE 
    (COALESCE(rw.total_quantity, 0) > 10 OR ISNULL(is.customer_count, 0) < 5)
    AND (rm.total_return_quantity IS NULL OR rm.total_return_quantity < 20)
ORDER BY 
    website, total_customers DESC, average_return_value DESC;
