
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS RankProfit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        COALESCE(cs.cs_quantity, 0) AS total_catalog_sales,
        COALESCE(ss.ss_quantity, 0) AS total_store_sales,
        COALESCE(ws.ws_quantity, 0) AS total_web_sales,
        COALESCE(cr.total_returns, 0) AS total_web_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value
    FROM customer c
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_catalog_sales,
    ss.total_store_sales,
    ss.total_web_sales,
    ss.total_web_returns,
    ss.total_return_value,
    COALESCE(rs.RankProfit, 0) AS ProfitRank
FROM SalesSummary ss
LEFT JOIN RankedSales rs ON ss.c_customer_sk = rs.web_site_sk
WHERE (ss.total_catalog_sales + ss.total_store_sales + ss.total_web_sales) > 100
AND (EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN 1 AND 6 OR ss.total_web_returns > 5)
ORDER BY ProfitRank, ss.c_last_name DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
