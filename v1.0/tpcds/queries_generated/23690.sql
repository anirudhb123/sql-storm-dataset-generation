
WITH RECURSIVE customer_spending AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_spending,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
customer_address_ranks AS (
    SELECT 
        ca.ca_address_sk,
        ROW_NUMBER() OVER(PARTITION BY ca.ca_country ORDER BY ca.ca_zip) AS zip_rank
    FROM 
        customer_address ca
),
demographic_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' AND cd.cd_dep_count IS NOT NULL THEN 'Married with Dependents' 
            WHEN cd.cd_marital_status = 'S' AND cd.cd_dep_count IS NOT NULL THEN 'Single with Dependents' 
            ELSE 'Other'
        END AS marital_info
    FROM 
        customer_demographics cd
),
monthly_sales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_month_seq
)
SELECT 
    cs.c_customer_id,
    cs.total_spending,
    ca.city,
    db.marital_info,
    COALESCE(m.monthly_sales, 0) AS monthly_sales,
    CASE 
        WHEN cs.total_orders > 10 THEN 'Frequent Shopper'
        WHEN cs.total_orders BETWEEN 5 AND 10 THEN 'Occasional Shopper'
        ELSE 'Rare Shopper'
    END AS shopper_category,
    CASE 
        WHEN ca.ca_zip LIKE '9%' THEN 'High Value Area'
        ELSE NULL
    END as value_area,
    RANK() OVER (ORDER BY cs.total_spending DESC) AS spending_rank
FROM 
    customer_spending cs
LEFT JOIN 
    customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    demographic_info db ON cs.c_customer_sk = db.cd_demo_sk
LEFT JOIN 
    monthly_sales m ON m.d_month_seq = EXTRACT(MONTH FROM CURRENT_DATE)
WHERE 
    cs.total_spending IS NOT NULL
    AND (db.cd_gender IS NULL OR db.cd_gender = 'F') 
ORDER BY 
    spending_rank 
LIMIT 100;
