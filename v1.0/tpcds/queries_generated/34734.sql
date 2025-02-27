
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        web_site AS w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.total_orders + COUNT(ws.ws_order_number),
        sh.total_profit + SUM(ws.ws_net_profit)
    FROM 
        sales_hierarchy AS sh
    JOIN 
        customer AS c ON sh.c_customer_sk = c.c_customer_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        sh.total_orders < 10 -- Arbitrary limit for recursion
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, sh.total_orders, sh.total_profit
),
filtered_sales AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(sh.total_orders, 0) AS order_count,
        COALESCE(sh.total_profit, 0) AS profit
    FROM 
        customer AS c
    LEFT JOIN 
        sales_hierarchy AS sh ON c.c_customer_sk = sh.c_customer_sk
),
ranked_sales AS (
    SELECT 
        f.full_name,
        f.order_count,
        f.profit,
        RANK() OVER (ORDER BY f.profit DESC) AS profit_rank,
        RANK() OVER (ORDER BY f.order_count DESC) AS order_rank
    FROM 
        filtered_sales AS f
    WHERE 
        f.order_count > 0 
)

SELECT 
    r.full_name,
    r.order_count,
    r.profit,
    CASE 
        WHEN r.profit_rank <= 5 THEN 'Top 5 Profit Generators'
        WHEN r.order_rank <= 5 THEN 'Top 5 Order Generators'
        ELSE 'Other'
    END AS category
FROM 
    ranked_sales AS r
WHERE 
    r.profit > AVG(r.profit) OVER () -- Analyze customers above average profit
ORDER BY 
    r.profit DESC;
