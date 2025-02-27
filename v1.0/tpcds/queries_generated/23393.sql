
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws.net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    AND 
        (c.c_preferred_cust_flag IS NOT NULL OR c.c_email_address LIKE '%@example.com')
),
customer_return_summary AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returns,
        COUNT(DISTINCT cr.order_number) AS return_orders
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
selected_returns AS (
    SELECT 
        cus.returning_customer_sk,
        cus.total_returns,
        cus.return_orders,
        COALESCE(sales.net_profit, 0) AS corresponding_net_profit
    FROM 
        customer_return_summary cus
    LEFT JOIN 
        ranked_sales sales ON cus.returning_customer_sk = sales.web_site_sk
)
SELECT 
    r.web_site_sk,
    r.order_number,
    r.net_profit,
    CASE 
        WHEN r.profit_rank = 1 THEN 'Top Profit'
        WHEN r.profit_rank BETWEEN 2 AND 5 THEN 'High Profit'
        ELSE 'Others'
    END AS profit_category,
    COALESCE(s.total_returns, 0) AS total_returns,
    s.return_orders
FROM 
    ranked_sales r
LEFT JOIN 
    selected_returns s ON r.web_site_sk = s.returning_customer_sk
WHERE 
    r.net_profit > (
        SELECT AVG(net_profit) 
        FROM ranked_sales 
        WHERE web_site_sk = r.web_site_sk
    )
ORDER BY 
    r.web_site_sk, r.net_profit DESC
LIMIT 50
OFFSET (SELECT COUNT(*) FROM ranked_sales WHERE profit_rank <= 5);
