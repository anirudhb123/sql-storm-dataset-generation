
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        sh.ws_item_sk, 
        sh.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY sh.total_net_profit DESC) AS overall_rank
    FROM 
        sales_hierarchy sh
    WHERE 
        sh.rank <= 5
),
item_details AS (
    SELECT 
        i.i_item_id, 
        i.i_product_name, 
        i.i_current_price, 
        COALESCE(tsp.total_net_profit, 0) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        top_sales tsp ON i.i_item_sk = tsp.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Unknown'
        END AS gender,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
)
SELECT 
    ci.c_customer_id,
    ci.gender,
    ci.total_orders,
    ci.total_spent,
    id.i_item_id,
    id.i_product_name,
    id.i_current_price,
    id.total_net_profit,
    CASE 
        WHEN ci.total_spent > 1000 THEN 'High Value'
        WHEN ci.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    customer_info ci
JOIN 
    item_details id ON ci.total_orders > 0 
ORDER BY 
    ci.total_spent DESC, 
    id.total_net_profit DESC;
