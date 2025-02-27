
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        AVG(ws.net_paid_inc_tax) AS avg_order_value,
        MAX(ws.net_paid) AS max_order_value,
        MIN(ws.net_paid) AS min_order_value,
        COUNT(DISTINCT ws.ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    JOIN 
        promotion p ON ws.promo_sk = p.p_promo_sk
    WHERE 
        dd.d_year = 2023 AND 
        p.p_discount_active = 'Y'
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd.purchase_estimate) AS total_estimated_purchase,
        AVG(cd.credit_rating) AS avg_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
)

SELECT 
    sd.web_site_id,
    sd.total_orders,
    sd.total_profit,
    sd.avg_order_value,
    sd.max_order_value,
    sd.min_order_value,
    cd.customer_count,
    cd.total_estimated_purchase,
    cd.avg_credit_rating
FROM 
    SalesData sd
LEFT JOIN 
    CustomerDemographics cd ON sd.total_orders > 10
ORDER BY 
    sd.total_profit DESC, sd.avg_order_value DESC
LIMIT 100;
