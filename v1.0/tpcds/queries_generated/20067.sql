
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        MIN(d_date) AS first_purchase_date,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        ws_bill_customer_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cs.total_profit,
        cs.total_orders,
        cs.first_purchase_date,
        CASE 
            WHEN cs.total_profit IS NULL THEN 'No Purchases' 
            WHEN cs.total_profit > 1000 THEN 'High Value' 
            WHEN cs.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value' 
            ELSE 'Low Value' 
        END AS customer_value_segment
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
)
SELECT 
    cu.c_customer_id, 
    CONCAT(cu.c_first_name, ' ', cu.c_last_name) AS full_name,
    cu.cd_gender,
    cu.customer_value_segment,
    COALESCE(ws_total_orders, 0) AS total_web_sales_orders,
    COALESCE(ss_total_orders, 0) AS total_store_sales_orders,
    COALESCE(ws_total_profit, 0) + COALESCE(ss_total_profit, 0) AS total_profit,
    CASE 
        WHEN cu.first_purchase_date IS NULL THEN 'N/A' 
        ELSE TO_CHAR(cu.first_purchase_date, 'YYYY-MM-DD') 
    END AS first_purchase_date,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS ranking 
FROM 
    customer_stats cu
LEFT JOIN (
    SELECT 
        ws_bill_customer_sk, 
        COUNT(ws_order_number) AS ws_total_orders, 
        SUM(ws_net_profit) AS ws_total_profit 
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
) ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN (
    SELECT 
        ss_customer_sk, 
        COUNT(ss_ticket_number) AS ss_total_orders, 
        SUM(ss_net_profit) AS ss_total_profit 
    FROM 
        store_sales 
    GROUP BY 
        ss_customer_sk
) ss ON cu.c_customer_sk = ss.ss_customer_sk
WHERE 
    cu.customer_value_segment <> 'No Purchases' 
    AND (cu.cd_gender IS NOT NULL OR cu.cd_marital_status IS NOT NULL)
ORDER BY 
    ranking, cu.c_customer_id;
