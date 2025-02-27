
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sale_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
SalesWithDemographics AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        rs.total_sales,
        rs.ws_bill_customer_sk
    FROM RankedSales rs
    JOIN customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregatedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    WHERE wr_return_amt IS NOT NULL
    GROUP BY wr_returning_customer_sk
),
ReturnAnalysis AS (
    SELECT 
        swd.*,
        ar.total_return_amt,
        ar.return_count,
        COALESCE((ar.total_return_amt / NULLIF(swd.total_sales, 0)), 0) AS return_ratio
    FROM SalesWithDemographics swd
    LEFT JOIN AggregatedReturns ar ON swd.ws_bill_customer_sk = ar.wr_returning_customer_sk
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.total_sales,
    r.total_return_amt,
    r.return_count,
    r.return_ratio,
    CASE 
        WHEN r.return_ratio > 0.5 THEN 'High Return'
        WHEN r.return_ratio BETWEEN 0.2 AND 0.5 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    ReturnAnalysis r
WHERE 
    EXISTS (
        SELECT 1
        FROM customer_address ca 
        WHERE ca.ca_address_sk = (
            SELECT c_current_addr_sk
            FROM customer 
            WHERE c_customer_sk = r.ws_bill_customer_sk
        ) AND ca.ca_city = 'New York'
    )
ORDER BY r.total_sales DESC, r.return_ratio ASC
LIMIT 100;
