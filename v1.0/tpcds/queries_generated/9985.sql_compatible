
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.quantity) AS avg_quantity_per_order,
        SUM(ws.net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_id
),
CustomerData AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_dep_count) AS max_dependents
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
),
CombinedData AS (
    SELECT 
        sd.web_site_id,
        sd.total_net_profit,
        sd.total_orders,
        sd.avg_quantity_per_order,
        sd.total_revenue,
        cd.total_customers,
        cd.avg_purchase_estimate,
        cd.max_dependents
    FROM 
        SalesData AS sd
    JOIN 
        CustomerData AS cd ON cd.cd_demo_sk IS NOT NULL
)
SELECT 
    web_site_id,
    total_net_profit,
    total_orders,
    avg_quantity_per_order,
    total_revenue,
    total_customers,
    avg_purchase_estimate,
    max_dependents
FROM 
    CombinedData
ORDER BY 
    total_net_profit DESC
LIMIT 10;
