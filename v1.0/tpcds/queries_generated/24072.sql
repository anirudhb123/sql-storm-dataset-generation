
WITH RevenueCTE AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_id
),
CustomerCTE AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RevenueCTE
)
SELECT 
    cw.web_site_id,
    cw.total_revenue,
    COALESCE(cc.orders_count, 0) AS customer_orders_count,
    cc.cd_gender,
    cc.cd_marital_status
FROM 
    TopWebsites cw
LEFT JOIN 
    CustomerCTE cc ON cw.web_site_id = cc.c_customer_id 
WHERE 
    cw.revenue_rank <= 10
    AND (cc.orders_count IS NULL OR cc.total_profit > 1000)
ORDER BY 
    cw.total_revenue DESC;

-- Expanding with a bizarre logic: find customers whose web site revenue contributed significantly 
-- alongside their characteristic of having more than one order or no orders at all.
UNION ALL
SELECT 
    cw.web_site_id,
    COUNT(DISTINCT cc.c_customer_id) AS unique_customers,
    SUM(CASE WHEN cc.orders_count > 1 THEN 1 ELSE 0 END) AS repeat_customers
FROM 
    TopWebsites cw
INNER JOIN 
    CustomerCTE cc ON cw.web_site_id = cc.c_customer_id
WHERE 
    cw.total_revenue > (
        SELECT AVG(total_revenue) FROM RevenueCTE
    )
    AND cc.cd_marital_status IS NOT NULL
GROUP BY 
    cw.web_site_id
HAVING 
    COUNT(DISTINCT cc.c_customer_id) > 5
ORDER BY 
    unique_customers DESC;
