
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        customer AS c
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
promotional_sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(ws.ws_order_number) AS web_order_count
    FROM 
        web_sales AS ws
    INNER JOIN 
        promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        ws.ws_bill_customer_sk
),
combined_sales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales_profit,
        COALESCE(ps.web_profit, 0) AS web_profit,
        COALESCE(cs.total_transactions, 0) AS total_transactions,
        COALESCE(ps.web_order_count, 0) AS web_order_count
    FROM 
        customer_sales AS cs
    LEFT JOIN 
        promotional_sales AS ps ON cs.c_customer_id = ps.ws_bill_customer_sk
),
ranked_sales AS (
    SELECT 
        c.customer_id, 
        total_sales_profit, 
        web_profit, 
        total_transactions, 
        web_order_count,
        RANK() OVER (ORDER BY total_sales_profit + web_profit DESC) AS sales_rank
    FROM 
        combined_sales c
)
SELECT 
    r.customer_id,
    r.total_sales_profit + r.web_profit AS total_profit,
    r.total_transactions,
    r.web_order_count,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top Performer'
        WHEN r.total_profit > 1000 THEN 'Above Average'
        ELSE 'Regular'
    END AS performance_category
FROM 
    ranked_sales r
WHERE 
    (r.total_transactions > 0 OR r.web_order_count > 0)
ORDER BY 
    total_profit DESC;
