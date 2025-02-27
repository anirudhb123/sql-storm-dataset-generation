
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
high_value_customers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM 
        customer_info c
    WHERE 
        total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                customer_info
        )
),
promotion_summary AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    p.p_promo_name,
    ps.total_profit,
    ps.total_orders,
    hv.spend_rank
FROM 
    high_value_customers hv
JOIN 
    customer_demographics c ON hv.c_current_cdemo_sk = c.cd_demo_sk
LEFT JOIN 
    promotion_summary ps ON hv.total_spent > ps.total_profit
WHERE 
    c.cd_marital_status = 'M' AND 
    (c.cd_gender = 'F' OR c.cd_gender IS NULL)
ORDER BY 
    hv.spend_rank, ps.profit_rank;
