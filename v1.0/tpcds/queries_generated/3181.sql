
WITH RevenueData AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM web_sales ws
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    GROUP BY ws.web_site_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_credit_rating) AS best_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    GROUP BY cd.cd_demo_sk
),
RankedRevenue AS (
    SELECT 
        rd.web_site_sk,
        rd.total_net_profit,
        rd.order_count,
        rd.avg_net_paid,
        rd.return_count,
        RANK() OVER (ORDER BY rd.total_net_profit DESC) AS profit_rank
    FROM RevenueData rd
)
SELECT 
    r.web_site_sk,
    r.total_net_profit,
    r.order_count,
    r.avg_net_paid,
    r.return_count,
    cd.customer_count,
    cd.avg_purchase_estimate,
    cd.best_credit_rating,
    COALESCE(NULLIF(r.return_count, 0), 0) AS adjusted_return_count
FROM RankedRevenue r
JOIN CustomerDemographics cd ON r.web_site_sk = cd.cd_demo_sk
WHERE r.profit_rank <= 10
UNION ALL
SELECT 
    NULL AS web_site_sk,
    NULL AS total_net_profit,
    0 AS order_count,
    NULL AS avg_net_paid,
    NULL AS return_count,
    SUM(cd.customer_count) AS customer_count,
    AVG(cd.avg_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.best_credit_rating) AS best_credit_rating
FROM CustomerDemographics cd
WHERE cd.customer_count > 1000
GROUP BY cd.cd_demo_sk
HAVING COUNT(cd.cd_demo_sk) > 1
ORDER BY total_net_profit DESC NULLS LAST;
