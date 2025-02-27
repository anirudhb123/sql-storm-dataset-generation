
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_profit DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_first_name IS NOT NULL AND c.c_last_name IS NOT NULL
),
SalesSummary AS (
    SELECT
        rs.web_site_id,
        SUM(rs.ws_net_profit) AS total_profit,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders
    FROM RankedSales rs
    WHERE rs.rank <= 10
    GROUP BY rs.web_site_id
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT
    ss.web_site_id,
    ss.total_profit,
    ss.total_orders,
    cd.cd_gender,
    COALESCE(cd.customer_count, 0) AS customer_count,
    CASE 
        WHEN ss.total_profit > 10000 THEN 'High Profit'
        WHEN ss.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM SalesSummary ss
LEFT JOIN CustomerDemographics cd ON ss.web_site_id = cd.cd_demo_sk
ORDER BY ss.total_profit DESC, cd.cd_gender;
