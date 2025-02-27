
WITH RECURSIVE revenue_cte AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
    
    UNION ALL
    
    SELECT 
        rc.web_site_sk,
        SUM(ws.net_profit)
    FROM 
        revenue_cte rc
    JOIN 
        web_sales ws ON rc.web_site_sk = ws.web_site_sk
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        rc.web_site_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.net_profit) AS total_spent,
        AVG(ws.net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
demographics_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        cd.cd_demo_sk
),
combined_summary AS (
    SELECT 
        cs.order_count,
        cs.total_spent,
        cs.avg_order_value,
        ds.customer_count,
        ds.total_profit,
        ds.avg_purchase_estimate,
        r.total_revenue
    FROM 
        customer_summary cs
    JOIN 
        demographics_summary ds ON cs.c_customer_sk = ds.customer_count
    LEFT JOIN 
        revenue_cte r ON r.web_site_sk = cs.order_count
)
SELECT 
    AVG(total_spent) AS avg_total_spent,
    AVG(total_profit) AS avg_total_profit,
    MAX(avg_order_value) AS max_avg_order_value,
    MIN(customer_count) AS min_customer_count,
    SUM(total_revenue) AS overall_revenue
FROM 
    combined_summary
WHERE 
    total_spent IS NOT NULL
    AND total_profit IS NOT NULL
    AND customer_count > 0
GROUP BY 
    total_revenue
ORDER BY 
    overall_revenue DESC
LIMIT 10;
