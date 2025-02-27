
WITH RECURSIVE IncomeBands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound >= 0
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    INNER JOIN IncomeBands ibs ON ib.ib_income_band_sk = ibs.ib_income_band_sk + 1
),
RankedCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender,
           SUM(ws.ws_net_paid) AS Total_Sales,
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS Sales_Rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
SalesReturns AS (
    SELECT sr.returned_amount, sr.reason
    FROM (
        SELECT sr_customer_sk, SUM(sr_return_amt_inc_tax) AS returned_amount,
               COALESCE(r.r_reason_desc, 'Unknown') AS reason
        FROM store_returns sr
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        GROUP BY sr_customer_sk, r.r_reason_desc
    ) AS sr
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS Full_Name,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
    SUM(ws.ws_net_paid) AS Total_Sales,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = c.c_customer_sk) AS Store_Sales_Count,
    RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS Overall_Sales_Rank,
    CASE
        WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High Value'
        WHEN SUM(ws.ws_net_paid) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_Value
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN IncomeBands ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
GROUP BY c.c_first_name, c.c_last_name, cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(DISTINCT ws.ws_order_number) > 1
ORDER BY Total_Sales DESC
LIMIT 100;

