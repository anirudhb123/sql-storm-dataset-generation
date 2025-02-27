
WITH total_sales AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_net_profit) AS total_net_profit, 
        COUNT(cs_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        ts.total_net_profit, 
        ts.total_orders
    FROM 
        item i
    JOIN 
        total_sales ts ON i.i_item_sk = ts.cs_item_sk
    WHERE 
        ts.profit_rank <= 10
),
customer_summary AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_purchases,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date,
        MAX(cd.cd_marital_status) AS marital_status
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
),
customer_items AS (
    SELECT 
        cs.c_customer_id,
        ti.i_item_id,
        ti.i_item_desc
    FROM 
        customer_summary cs
    JOIN 
        web_sales ws ON cs.c_customer_id = ws.ws_bill_customer_sk
    JOIN 
        item ti ON ws.ws_item_sk = ti.i_item_sk
    WHERE 
        cs.last_purchase_date = (SELECT MAX(last_purchase_date) FROM customer_summary)
)
SELECT 
    ci.c_customer_id,
    ci.i_item_id,
    ci.i_item_desc,
    cs.total_spent,
    cs.total_purchases,
    cs.marital_status,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_status 
FROM 
    customer_items ci
JOIN 
    customer_summary cs ON ci.c_customer_id = cs.c_customer_id
ORDER BY 
    cs.total_spent DESC
LIMIT 100
```
