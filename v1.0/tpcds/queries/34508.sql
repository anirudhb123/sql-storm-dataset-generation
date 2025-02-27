
WITH RECURSIVE monthly_sales AS (
    SELECT 
        d.d_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY d.d_date DESC) AS month_seq
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date_sk
), 

store_analysis AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(ss.ss_item_sk) AS items_sold,
        SUM(ss.ss_net_paid) AS total_net_revenue,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        MAX(ss.ss_sales_price) AS max_sales_price,
        MIN(ss.ss_sales_price) AS min_sales_price
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_state = 'CA'
    GROUP BY 
        s.s_store_sk, s.s_store_name
),

customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, CONCAT(c.c_first_name, ' ', c.c_last_name), cd.cd_gender, cd.cd_marital_status
)

SELECT 
    ma.month_seq,
    ma.total_sales,
    sa.s_store_name,
    sa.items_sold,
    sa.total_net_revenue,
    ca.customer_name,
    ca.total_spent,
    CASE 
        WHEN ca.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Purchased'
    END AS purchase_status
FROM 
    monthly_sales ma
FULL OUTER JOIN 
    store_analysis sa ON ma.month_seq = sa.s_store_sk
FULL OUTER JOIN 
    customer_analysis ca ON sa.items_sold = ca.total_spent
WHERE 
    (sa.total_net_revenue > (SELECT AVG(total_net_revenue) FROM store_analysis) 
     OR ca.total_spent > 1000)
    AND ma.total_sales IS NOT NULL
ORDER BY 
    ma.month_seq DESC, 
    sa.total_net_revenue DESC;
