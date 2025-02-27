
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        1 AS hierarchy_level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        sh.hierarchy_level + 1
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_hierarchy sh ON cd.cd_demo_sk = sh.c_current_cdemo_sk
    WHERE 
        cd.cd_marital_status = 'M'
), 
sales_performance AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS ranking
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id
),
customer_ranking AS (
    SELECT 
        sh.c_current_cdemo_sk,
        COUNT(*) AS customer_count,
        AVG(sales.total_net_profit) AS avg_profit,
        RANK() OVER (ORDER BY AVG(sales.total_net_profit) DESC) AS rank
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        sales_performance sales ON sh.c_current_cdemo_sk = sales.web_site_id
    GROUP BY 
        sh.c_current_cdemo_sk
)
SELECT 
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    cd.cd_income_band_sk,
    cr.customer_count,
    cr.avg_profit,
    mp.warehouse_id,
    mp.avg_payment,
    mp.total_revenue
FROM 
    customer cust
JOIN 
    customer_ranking cr ON cust.c_current_cdemo_sk = cr.c_current_cdemo_sk
LEFT JOIN (
    SELECT 
        w.w_warehouse_id,
        AVG(ws.ws_net_paid_inc_tax) AS avg_payment,
        SUM(ws.ws_net_profit) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
) mp ON cr.c_current_cdemo_sk = mp.warehouse_id
WHERE 
    cr.rank <= 10
ORDER BY 
    cr.avg_profit DESC;
