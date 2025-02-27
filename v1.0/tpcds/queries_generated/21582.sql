
WITH EstimatedIncome AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_purchase_estimate BETWEEN 0 AND 10000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 10001 AND 30000 THEN 'Medium'
            WHEN cd_purchase_estimate BETWEEN 30001 AND 60000 THEN 'High'
            ELSE 'Very High'
        END AS income_category,
        COUNT(c_customer_sk) AS customer_count
    FROM customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_demo_sk, 
             CASE 
                 WHEN cd_purchase_estimate BETWEEN 0 AND 10000 THEN 'Low'
                 WHEN cd_purchase_estimate BETWEEN 10001 AND 30000 THEN 'Medium'
                 WHEN cd_purchase_estimate BETWEEN 30001 AND 60000 THEN 'High'
                 ELSE 'Very High'
             END
),
PromotionalSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY ws.web_site_id
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
ReturnStats AS (
    SELECT 
        dr.d_date,
        COALESCE(SUM(cr.total_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(cr.total_return_amount), 0) AS total_return_amount
    FROM date_dim dr
    LEFT JOIN CustomerReturns cr ON dr.d_date_sk = cr.sr_returned_date_sk
    GROUP BY dr.d_date
),
IncomeStats AS (
    SELECT 
        ei.income_category,
        SUM(es.customer_count) AS total_customers,
        SUM(COALESCE(rs.total_return_quantity, 0)) AS total_returns
    FROM EstimatedIncome ei
    LEFT JOIN PromotionalSales ps ON ei.cd_demo_sk = ps.web_site_id
    LEFT JOIN ReturnStats rs ON ei.cd_demo_sk = rs.total_return_quantity
    GROUP BY ei.income_category
)
SELECT 
    income_category,
    total_customers,
    total_returns,
    ROUND((total_returns::decimal / total_customers::decimal) * 100, 2) AS return_percentage
FROM IncomeStats
WHERE total_customers > 0
ORDER BY return_percentage DESC;
