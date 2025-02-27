
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_per_site
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2456500 AND 2456670
    GROUP BY ws.web_site_sk, ws.web_site_id
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M' 
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)

SELECT 
    R.web_site_id,
    R.total_quantity,
    R.total_profit,
    C.total_returns,
    C.total_return_amount,
    D.customer_count 
FROM RankedSales R
LEFT JOIN CustomerReturns C ON R.web_site_sk = C.wr_returning_customer_sk
LEFT JOIN CustomerDemographics D ON R.total_profit > (SELECT AVG(total_profit) FROM RankedSales)
WHERE R.rank_per_site = 1
ORDER BY R.total_profit DESC
LIMIT 10;
