
WITH RankedReturns AS (
    SELECT 
        COALESCE(sr.return_quantity, 0) AS return_quantity,
        COALESCE(ws.ws_quantity, 0) AS sold_quantity,
        COALESCE(sr.return_quantity, 0) - COALESCE(ws.ws_quantity, 0) AS net_difference,
        RANK() OVER (PARTITION BY sr.returned_date_sk, sr.returning_customer_sk ORDER BY return_quantity DESC) AS rnk
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        web_sales ws ON sr.sr_item_sk = ws.ws_item_sk AND sr.sr_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        COALESCE(sr.returned_date_sk, -1) <> -1 OR COALESCE(ws.ws_sold_date_sk, -1) <> -1
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cd.c_customer_id, 
    cd.ca_city,
    SUM(CASE WHEN rr.rnk = 1 THEN rr.net_difference ELSE NULL END) AS highest_return_difference,
    AVG(CASE WHEN rr.return_quantity > 0 THEN rr.return_quantity ELSE NULL END) AS avg_positive_returns,
    COUNT(DISTINCT CASE WHEN cd.gender_rank = 1 THEN c.c_customer_id END) AS top_gender_customers,
    CONCAT('Total Returns: ', CAST(SUM(rr.return_quantity) AS VARCHAR)) AS return_summary
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedReturns rr ON cd.c_customer_id = rr.returning_customer_sk
WHERE 
    cd.cd_marital_status IS NOT NULL
GROUP BY 
    cd.c_customer_id, cd.ca_city
HAVING 
    SUM(rr.return_quantity) > 0 OR COUNT(rr.return_quantity) < 3
ORDER BY 
    highest_return_difference DESC, avg_positive_returns ASC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
