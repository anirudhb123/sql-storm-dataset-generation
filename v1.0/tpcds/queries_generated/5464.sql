
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        d.d_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY ws.web_site_id, d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
PromotionSummary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_usage_count,
        SUM(ws.ws_net_profit) AS promo_revenue
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id
)
SELECT 
    ss.web_site_id,
    ss.total_net_profit,
    ss.total_orders,
    ss.avg_sales_price,
    ss.total_quantity_sold,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.customer_count,
    ps.p_promo_id,
    ps.promo_usage_count,
    ps.promo_revenue
FROM SalesSummary ss
JOIN CustomerDemographics cd ON 1=1
JOIN PromotionSummary ps ON ps.promo_usage_count > 0
ORDER BY ss.web_site_id, ss.total_net_profit DESC, cd.customer_count DESC;
