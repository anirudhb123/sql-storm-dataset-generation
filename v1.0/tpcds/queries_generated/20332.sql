
WITH RankedReturns AS (
    SELECT 
        sr.returning_customer_sk,
        sr_reason_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr.returning_customer_sk ORDER BY COUNT(*) DESC) AS rank_by_customer
    FROM store_returns sr
    WHERE sr_return_amt_inc_tax > 0
    GROUP BY sr.returning_customer_sk, sr_reason_sk
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(da.total_return_amt, 0) AS last_year_return_amt,
        CASE 
            WHEN da.total_return_amt IS NULL THEN 'No Returns'
            ELSE 
                CASE 
                    WHEN da.total_return_amt > 500 THEN 'High Returns'
                    WHEN da.total_return_amt BETWEEN 200 AND 500 THEN 'Moderate Returns'
                    ELSE 'Low Returns'
                END
        END AS return_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            returning_customer_sk,
            SUM(total_return_amt) AS total_return_amt
        FROM RankedReturns
        WHERE rank_by_customer = 1
        GROUP BY returning_customer_sk
    ) da ON c.c_customer_sk = da.returning_customer_sk
),
MonthlySales AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_year, d.d_month_seq
),
TopCustomerSales AS (
    SELECT 
        ca.c_customer_id,
        ca.c_first_name,
        ca.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer_analysis ca
    JOIN web_sales ws ON ca.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY ca.c_customer_id, ca.c_first_name, ca.c_last_name
    HAVING SUM(ws.ws_ext_sales_price) > (
        SELECT AVG(total_sales)
        FROM MonthlySales
    )
)
SELECT 
    ca.c_customer_id,
    ca.c_first_name,
    ca.c_last_name,
    ca.cd_gender,
    ca.cd_marital_status,
    ca.return_status,
    ts.total_sales AS customer_sales
FROM CustomerAnalysis ca
FULL OUTER JOIN TopCustomerSales ts ON ca.c_customer_id = ts.c_customer_id
WHERE (ca.return_status = 'High Returns' OR ts.total_sales IS NOT NULL)
ORDER BY ca.c_last_name, ca.c_first_name;
