
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_profit) AS TotalProfit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS ProfitRank
    FROM web_sales ws
    WHERE ws.sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY ws.web_site_sk
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(DISTINCT cr.return_order_number) AS TotalReturns,
        SUM(cr.return_amount) AS TotalReturnedAmount
    FROM web_returns cr
    WHERE cr.returned_date_sk IS NOT NULL
    GROUP BY cr.returning_customer_sk
),
JoinResults AS (
    SELECT 
        ca.city,
        ca.state,
        SUM(COALESCE(ws.net_profit, 0)) AS TotalSalesProfit,
        AVG(cd.dep_count) AS AvgDependents,
        MAX(rb.total_returns) AS MaxReturns
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN (SELECT 
                   returning_customer_sk,
                   COUNT(returning_customer_sk) AS total_returns
               FROM web_returns
               GROUP BY returning_customer_sk) rb ON c.c_customer_sk = rb.returning_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.city, ca.state
),
FinalResults AS (
    SELECT 
        cr.city,
        cr.state,
        cr.TotalSalesProfit,
        cr.AvgDependents,
        COALESCE(rc.TotalReturns, 0) AS TotalReturns,
        RANK() OVER (ORDER BY cr.TotalSalesProfit DESC) AS SalesRank
    FROM JoinResults cr
    LEFT JOIN CustomerReturns rc ON cr.city = rc.returning_customer_sk
)
SELECT 
    f.city,
    f.state,
    f.TotalSalesProfit,
    f.AvgDependents,
    f.TotalReturns,
    CASE
        WHEN f.SalesRank <= 10 THEN 'Top City'
        ELSE 'Regular City'
    END AS CityRank
FROM FinalResults f
ORDER BY f.TotalSalesProfit DESC, f.AvgDependents DESC
LIMIT 50
OFFSET 5;
