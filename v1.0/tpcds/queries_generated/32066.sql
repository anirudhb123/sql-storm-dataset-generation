
WITH RECURSIVE SalesGrowth AS (
    SELECT d_year, SUM(ws_net_profit) AS total_profit
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
    UNION ALL
    SELECT d_year - 1, SUM(ws_net_profit) * 1.1
    FROM SalesGrowth
    WHERE d_year > 2000
    GROUP BY d_year
),
RecentReturns AS (
    SELECT DISTINCT wr_returning_customer_sk, SUM(wr_return_qty) AS total_return
    FROM web_returns
    WHERE wr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT cd_gender, COUNT(c_customer_sk) AS customer_count,
           SUM(hd_dep_count) AS total_dependents
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    GROUP BY cd_gender
)
SELECT c.c_customer_id, c.c_first_name, c.c_last_name, cd.customer_count,
       cd.total_dependents, COALESCE(rr.total_return, 0) AS total_returns,
       sg.total_profit
FROM customer c
LEFT JOIN CustomerDemographics cd ON 1=1
LEFT JOIN RecentReturns rr ON rr.wr_returning_customer_sk = c.c_customer_sk
JOIN SalesGrowth sg ON sg.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE c.c_birth_year BETWEEN 1970 AND 1990
  AND c.c_preferred_cust_flag = 'Y'
ORDER BY total_returns DESC, sg.total_profit DESC
LIMIT 100;
