
WITH RECURSIVE sales_totals AS (
    SELECT 
        ws_order_number, 
        SUM(ws_net_profit) AS total_net_profit, 
        COUNT(ws_item_sk) AS total_items_sold,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY SUM(ws_net_profit) DESC) AS rank_order
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451560 
    GROUP BY 
        ws_order_number
), 
customer_metrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_order_number END) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased,
        AVG(ws.ws_net_profit) OVER (PARTITION BY c.c_customer_sk) AS avg_profit_per_order
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
customer_ranks AS (
    SELECT 
        cm.*, 
        RANK() OVER (ORDER BY cm.total_spent DESC) AS spending_rank
    FROM 
        customer_metrics cm
), 
top_customers AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_spent,
        cr.total_orders,
        cr.unique_items_purchased,
        cr.avg_profit_per_order,
        CASE 
            WHEN cr.spending_rank <= 10 THEN 'Top 10'
            ELSE 'Other'
        END AS customer_tier
    FROM 
        customer_ranks cr
    WHERE 
        cr.total_orders > 0
)

SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_orders,
    tc.unique_items_purchased,
    tc.avg_profit_per_order,
    COALESCE(st.total_net_profit, 0) AS avg_net_profit_from_top_sales
FROM 
    top_customers tc
LEFT JOIN 
    sales_totals st ON tc.total_orders = st.total_items_sold
WHERE 
    tc.customer_tier = 'Top 10'
ORDER BY 
    tc.total_spent DESC;
