
WITH CustomerReturns AS (
    SELECT  
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned_quantity,
        SUM(cr.return_amt) AS total_returned_amt,
        AVG(cr.net_loss) AS avg_net_loss,
        MAX(cr.return_ship_cost) AS max_return_ship_cost
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_ship_customer_sk,
        ws_item_sk,
        ws.quantity AS sold_quantity,
        ws.net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_ship_customer_sk ORDER BY ws.sold_date_sk DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SUM(sd.sold_quantity), 0) AS total_sold_quantity,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
    COUNT(DISTINCT cs_item_sk) AS unique_items_purchased,
    CASE 
        WHEN AVG(sd.net_profit) IS NULL THEN 'No sales' 
        ELSE 'Sales available' 
    END AS sales_status,
    (SELECT COUNT(*) FROM store WHERE s_state = 'CA') AS total_stores_in_CA
FROM 
    CustomerDemographics cd
LEFT JOIN 
    SalesData sd ON cd.cd_demo_sk = sd.ws_ship_customer_sk
LEFT JOIN 
    CustomerReturns cr ON cr.returning_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
GROUP BY 
    cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cr.total_returned_quantity, cr.total_returned_amt
HAVING 
    (SUM(sd.sold_quantity) IS NOT NULL AND SUM(sd.sold_quantity) > 0)
    OR (SUM(sd.sold_quantity) IS NULL AND cr.total_returned_quantity > 0)
ORDER BY 
    total_returned_amt DESC
LIMIT 50;
