
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE dd.d_year = 2023 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND (p.p_discount_active = 'Y' OR p.p_start_date_sk IS NOT NULL)
    GROUP BY ws.web_site_id
)

SELECT 
    ws.web_site_id,
    ss.total_sales,
    ss.total_orders,
    ss.average_profit,
    ss.unique_customers,
    CASE WHEN ss.total_sales > 1000000 THEN 'High Performer' 
         WHEN ss.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium Performer'
         ELSE 'Low Performer' END AS performance_category
FROM SalesSummary ss
JOIN web_site ws ON ss.web_site_id = ws.web_site_id
ORDER BY ss.total_sales DESC;
