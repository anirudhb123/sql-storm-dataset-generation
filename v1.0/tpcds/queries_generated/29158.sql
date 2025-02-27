
SELECT 
    SUBSTRING(c.c_first_name, 1, 1) || '. ' || INITCAP(c.c_last_name) AS customer_name,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent,
    AVG(ws.ws_net_profit) AS avg_profit,
    STRING_AGG(DISTINCT CONCAT(i.i_brand, ' ', i.i_product_name), ', ') AS purchased_items,
    MAX(d.d_date) AS last_purchase_date,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year BETWEEN 1985 AND 2000
    AND d.d_year = 2023
GROUP BY 
    c.c_customer_sk, cd.cd_gender
ORDER BY 
    total_spent DESC
LIMIT 100;
