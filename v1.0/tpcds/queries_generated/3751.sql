
WITH RankedReturns AS (
    SELECT 
        sr.customer_sk, 
        SUM(sr.return_quantity) AS total_returned_quantity,
        COUNT(*) AS return_count,
        RANK() OVER (PARTITION BY sr.customer_sk ORDER BY SUM(sr.return_quantity) DESC) AS rank_within_customer
    FROM store_returns sr
    GROUP BY sr.customer_sk
), 
CustomerIncome AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN hd.hd_income_band_sk = 1 THEN 'Low Income'
            WHEN hd.hd_income_band_sk = 2 THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_band,
        c.c_first_name,
        c.c_last_name
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
SalesSummary AS (
    SELECT 
        w.ws_bill_customer_sk,
        SUM(w.ws_sales_price) AS total_spent,
        AVG(w.ws_net_profit) AS avg_profit
    FROM web_sales w
    WHERE w.ws_sold_date_sk >= (SELECT DENSE_RANK() OVER (ORDER BY d_date DESC) 
                                 FROM date_dim 
                                 WHERE d_year = 2023 AND d_month_seq = 1)
    GROUP BY w.ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.income_band,
    sr.total_returned_quantity,
    ss.total_spent,
    ss.avg_profit
FROM CustomerIncome ci
LEFT JOIN RankedReturns sr ON ci.c_customer_sk = sr.customer_sk AND sr.rank_within_customer = 1
LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE (sr.total_returned_quantity IS NULL OR sr.total_returned_quantity > 5)
AND (ss.total_spent IS NOT NULL AND ss.avg_profit > 0)
ORDER BY ci.income_band, ss.total_spent DESC;
