
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id
),
ReturnSummary AS (
    SELECT 
        wr.web_page_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_order_number) AS total_returns
    FROM web_returns wr
    GROUP BY wr.web_page_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.web_site_id,
    ss.total_net_profit,
    ss.total_orders,
    ss.avg_order_value,
    ss.unique_customers,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    COALESCE(rs.total_returns, 0) AS total_returns,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.avg_purchase_estimate
FROM SalesSummary ss
LEFT JOIN ReturnSummary rs ON ss.web_site_id = rs.web_page_sk
CROSS JOIN CustomerDemographics cd
WHERE ss.total_net_profit > (SELECT AVG(total_net_profit) FROM SalesSummary)
ORDER BY ss.total_net_profit DESC, ss.total_orders DESC;
