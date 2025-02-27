
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demo cdem ON ws.ws_bill_cdemo_sk = cdem.cd_demo_sk
    WHERE 
        dd.d_year BETWEEN 2022 AND 2023
        AND cdem.cd_gender = 'F'
        AND ca.ca_state IN ('CA', 'NY')
    GROUP BY 
        ws.web_site_id
), promotion_summary AS (
    SELECT 
        ps.p_promo_id,
        SUM(ws.ws_ext_sales_price) AS promo_sales,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders
    FROM 
        promotion ps
    JOIN 
        web_sales ws ON ps.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        ps.p_promo_id
)
SELECT 
    ss.web_site_id,
    ss.total_sales,
    ss.total_orders,
    ss.avg_net_profit,
    ps.promo_sales,
    ps.promo_orders
FROM 
    sales_summary ss
LEFT JOIN 
    promotion_summary ps ON ss.web_site_id = ps.promo_id
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
