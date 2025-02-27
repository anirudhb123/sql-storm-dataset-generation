
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990 
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws.bill_customer_sk
),
high_value_customers AS (
    SELECT
        r.sales_id,
        r.total_net_profit,
        r.order_count,
        COALESCE(d.cd_gender, 'Unknown') AS gender,
        COALESCE(d.cd_marital_status, 'Unknown') AS marital_status,
        d.cd_purchase_estimate
    FROM 
        ranked_sales r
    LEFT JOIN 
        customer_demographics d ON r.bill_customer_sk = d.cd_demo_sk
    WHERE 
        r.profit_rank <= 10
),
inventory_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(i.i_current_price) AS avg_price
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    hvc.bill_customer_sk,
    hvc.total_net_profit,
    hvc.order_count,
    ISNULL(i.total_quantity, 0) AS inventory_total,
    i.avg_price,
    CASE
        WHEN hvc.order_count >= 10 THEN 'High Activity'
        ELSE 'Regular Activity'
    END AS activity_level
FROM 
    high_value_customers hvc
LEFT JOIN 
    inventory_summary i ON hvc.order_count = i.total_quantity
ORDER BY 
    hvc.total_net_profit DESC;
