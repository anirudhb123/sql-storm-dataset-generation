
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.cs_net_paid DESC) AS rn
    FROM 
        customer c
    JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    WHERE 
        cs.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
),
top_sales AS (
    SELECT 
        rs.c_customer_id,
        rs.cs_order_number,
        rs.cs_item_sk,
        rs.cs_net_paid
    FROM 
        ranked_sales rs
    WHERE 
        rs.rn <= 5
),
customer_demo AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(cd.cd_gender, 'UNKNOWN') AS gender,
    COALESCE(cd.cd_marital_status, 'UNKNOWN') AS marital_status,
    COUNT(DISTINCT ts.cs_order_number) AS total_orders,
    SUM(CASE 
        WHEN ts.cs_net_paid IS NOT NULL THEN ts.cs_net_paid 
        ELSE 0 END) AS total_revenue,
    AVG(CASE 
        WHEN ts.cs_net_paid IS NOT NULL THEN ts.cs_net_paid 
        ELSE NULL END) AS avg_order_value,
    STRING_AGG(DISTINCT CONCAT_WS(', ', it.i_item_desc, it.i_brand), '; ') AS top_items
FROM 
    top_sales ts
JOIN 
    customer c ON ts.c_customer_id = c.c_customer_id
LEFT JOIN 
    customer_demo cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    item it ON ts.cs_item_sk = it.i_item_sk
WHERE 
    cd.cd_purchase_estimate > 
        (SELECT AVG(cd_purchase_estimate) FROM customer_demographics) 
    OR cd.cd_marital_status IS NULL 
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_revenue DESC;
