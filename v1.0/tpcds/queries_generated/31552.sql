
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
profits AS (
    SELECT 
        s.c_first_name,
        s.c_last_name,
        s.total_profit,
        DENSE_RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank
    FROM 
        sales_hierarchy s
)
SELECT 
    p.c_first_name,
    p.c_last_name,
    p.total_profit,
    CASE 
        WHEN p.total_profit IS NULL THEN 'No Sales'
        WHEN p.total_profit > 1000 THEN 'High Roller'
        ELSE 'Casual Shopper'
    END AS shopper_type,
    COALESCE(b.c_demo_sk, -1) AS demo_sk
FROM 
    profits p
LEFT JOIN 
    customer_demographics b ON p.total_profit BETWEEN b.cd_purchase_estimate - 100 AND b.cd_purchase_estimate + 100
WHERE 
    p.profit_rank <= 10
ORDER BY 
    p.total_profit DESC;

WITH seasonal_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
),
average_sales AS (
    SELECT 
        d_year,
        AVG(total_profit) AS avg_profit
    FROM 
        seasonal_sales
    GROUP BY 
        d_year
)
SELECT 
    a.d_year,
    a.avg_profit,
    CASE 
        WHEN a.avg_profit > 50000 THEN 'High Growth'
        WHEN a.avg_profit BETWEEN 20000 AND 50000 THEN 'Moderate Growth'
        ELSE 'Low Growth'
    END AS growth_category
FROM 
    average_sales a
ORDER BY 
    a.d_year DESC;
