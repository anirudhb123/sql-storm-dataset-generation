
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_month_seq <= 6
    )
    GROUP BY ws.web_site_sk, ws.web_name
),
TopWebSites AS (
    SELECT
        web_site_sk,
        web_name,
        total_net_profit
    FROM RankedSales
    WHERE profit_rank <= 5
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    t.web_name,
    SUM(cr.return_count) AS total_returns,
    SUM(cr.total_returned_amount) AS total_amount_returned,
    AVG(cd.cd_dep_count) AS avg_dep_count,
    COUNT(DISTINCT cd.cd_demo_sk) AS total_customers
FROM TopWebSites t
LEFT JOIN CustomerReturns cr ON t.web_site_sk = cr.c_customer_sk
LEFT JOIN CustomerDemographics cd ON cr.c_customer_sk = cd.cd_demo_sk
GROUP BY t.web_name
ORDER BY total_amount_returned DESC
LIMIT 10;
