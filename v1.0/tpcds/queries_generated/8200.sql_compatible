
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        COUNT(DISTINCT CASE 
            WHEN cd.gender = 'F' THEN ws.bill_customer_sk 
            END) AS female_customers,
        COUNT(DISTINCT CASE 
            WHEN cd.gender = 'M' THEN ws.bill_customer_sk 
            END) AS male_customers,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.bill_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON ws.bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    JOIN 
        promotion p ON ws.promo_sk = p.p_promo_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
top_sites AS (
    SELECT
        web_site_id,
        total_net_profit,
        total_orders,
        female_customers,
        male_customers,
        avg_purchase_estimate,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        sales_summary
)
SELECT 
    web_site_id,
    total_net_profit,
    total_orders,
    female_customers,
    male_customers,
    avg_purchase_estimate
FROM 
    top_sites
WHERE 
    profit_rank <= 10
ORDER BY 
    total_net_profit DESC;
