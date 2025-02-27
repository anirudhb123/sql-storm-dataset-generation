
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS return_rank
    FROM store_returns 
    GROUP BY sr_customer_sk, sr_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_college_count
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
HighReturnCustomers AS (
    SELECT 
        rr.sr_customer_sk, 
        rr.total_returned_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) AS dependents
    FROM RankedReturns rr
    JOIN CustomerDemographics cd ON rr.sr_customer_sk = cd.c_customer_sk
    WHERE rr.return_rank = 1 AND rr.total_returned_quantity > (
        SELECT AVG(total_returned_quantity)
        FROM RankedReturns
    )
)
SELECT 
    c.c_customer_id,
    SUM(ws.ws_quantity) AS total_sales_quantity,
    SUM(ws.ws_sales_price) AS total_sales_value,
    MAX(CASE WHEN r.obs IS NOT NULL THEN 'Has Returns' ELSE 'No Returns' END) AS return_status,
    CASE 
        WHEN SUM(ws.ws_net_profit) IS NULL THEN 'No Profit Data'
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable Customer'
        ELSE 'Non-Profitable Customer' 
    END AS customer_status
FROM web_sales ws
JOIN HighReturnCustomers c ON ws.ws_ship_customer_sk = c.sr_customer_sk
LEFT JOIN (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS obs 
    FROM web_returns 
    GROUP BY wr_returning_customer_sk
) r ON ws.ws_ship_customer_sk = r.wr_returning_customer_sk
GROUP BY c.c_customer_id
HAVING SUM(ws.ws_quantity) > (SELECT AVG(ws_quantity) FROM web_sales)
ORDER BY total_sales_value DESC
LIMIT 10;
