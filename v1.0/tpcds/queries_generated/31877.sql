
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_sold_date_sk, 
        ss_item_sk, 
        ss_ticket_number, 
        ss_quantity, 
        ss_net_profit, 
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_net_profit > 100

    UNION ALL

    SELECT 
        ss.sold_date_sk, 
        ss.item_sk, 
        ss.ticket_number, 
        ss.quantity, 
        ss.net_profit,
        sh.level + 1
    FROM 
        store_sales ss
    JOIN 
        sales_hierarchy sh ON ss.item_sk = sh.ss_item_sk AND sh.level < 5
    WHERE 
        ss.net_profit < sh.ss_net_profit
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
profit_summary AS (
    SELECT 
        sh.ss_item_sk,
        SUM(sh.ss_net_profit) AS total_net_profit,
        COUNT(sh.ss_ticket_number) AS total_sales
    FROM 
        sales_hierarchy sh
    GROUP BY 
        sh.ss_item_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    ps.total_net_profit,
    ps.total_sales,
    COALESCE(ps.total_net_profit / NULLIF(cs.total_spent, 0), 0) AS profit_margin,
    DENSE_RANK() OVER (ORDER BY ps.total_net_profit DESC) AS rank
FROM 
    customer_summary cs
LEFT JOIN 
    profit_summary ps ON cs.c_customer_sk = ps.ss_item_sk
WHERE 
    cs.total_spent > 1000
ORDER BY 
    profit_margin DESC
FETCH FIRST 10 ROWS ONLY;
