
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_net_profit
    FROM 
        web_sales ws
    LEFT JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    GROUP BY 
        ws.web_site_sk, ws.web_name

    UNION ALL

    SELECT 
        sh.web_site_sk,
        sh.web_name,
        COALESCE(SUM(ss2.ss_net_profit), 0) + sh.total_net_profit AS total_net_profit
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales ss2 ON sh.web_site_sk = ss2.ss_store_sk
    GROUP BY 
        sh.web_site_sk, sh.web_name, sh.total_net_profit
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
        AND (cd.cd_credit_rating IS NULL OR cd.cd_credit_rating <> 'Low')
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        customer_summary cs
    WHERE 
        cs.total_orders > 5
)
SELECT 
    s.web_name,
    th.c_customer_sk,
    th.total_spent,
    th.spending_rank
FROM 
    sales_hierarchy s
JOIN 
    top_customers th ON s.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_hierarchy)
ORDER BY 
    s.web_name, th.total_spent DESC;
