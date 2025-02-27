
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS recency_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
promo_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs_order_number) AS num_orders
    FROM 
        catalog_sales
    WHERE 
        EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = cs_promo_sk 
            AND p.p_discount_active = 'Y'
        )
    GROUP BY 
        cs_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_spending
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
date_filtered AS (
    SELECT 
        d.d_date,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        d.d_date
)
SELECT 
    ca.ca_city,
    AVG(s.total_net_paid) AS avg_net_paid,
    SUM(p.total_discount) AS total_discount_received,
    SUM(c.total_orders) AS total_orders_by_gender,
    d.order_count,
    d.total_revenue,
    CASE 
        WHEN AVG(s.total_net_paid) IS NULL THEN 'No Sales'
        WHEN AVG(s.total_net_paid) > 100 THEN 'High Spending'
        ELSE 'Low Spending'
    END AS spending_category
FROM 
    customer_address ca
LEFT JOIN 
    sales_data s ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = s.ws_item_sk)
LEFT JOIN 
    promo_summary p ON s.ws_item_sk = p.cs_item_sk
LEFT JOIN 
    customer_summary c ON c.c_customer_id = ca.ca_address_id
JOIN 
    date_filtered d ON d.order_count > 0
WHERE 
    ca.ca_country IS NOT NULL
GROUP BY 
    ca.ca_city, d.order_count, d.total_revenue
HAVING 
    COUNT(s.total_net_paid) > 5 
ORDER BY 
    total_revenue DESC
OPTION (MAXRECURSION 100);
