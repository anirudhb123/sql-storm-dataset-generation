
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS revenue_rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk 
    WHERE 
        i.i_current_price IS NOT NULL AND 
        i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_class_id = i.i_class_id)
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk, ws_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY AVG(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    SUM(CASE WHEN cs.order_count > 0 THEN cs.avg_order_value ELSE 0 END) AS total_avg_order_value,
    SUM(CASE WHEN cs.gender_rank <= 3 THEN 1 ELSE 0 END) AS top_gender_customers,
    AVG(ss.total_revenue) AS avg_site_revenue
FROM 
    customer_address ca
JOIN 
    customer_stats cs ON ca.ca_address_sk = cs.c_customer_sk 
LEFT JOIN 
    sales_summary ss ON ca.ca_address_sk = ss.web_site_sk
WHERE 
    ca.ca_state IN ('TX', 'CA') AND 
    (cs.order_count IS NULL OR cs.order_count > 5) 
    AND ss.total_quantity IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT cs.c_customer_sk) > 10
ORDER BY 
    total_avg_order_value DESC, unique_customers DESC
LIMIT 10;
