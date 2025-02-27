
WITH RECURSIVE sales_tree AS (
    SELECT 
        ss_store_sk, 
        ss_item_sk, 
        ss_quantity, 
        ss_net_paid, 
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL
    
    SELECT 
        st.ss_store_sk, 
        st.ss_item_sk, 
        st.ss_quantity, 
        st.ss_net_paid,
        st.level + 1
    FROM 
        sales_tree st
    JOIN 
        store_sales ss ON st.ss_item_sk = ss.ss_item_sk AND st.ss_store_sk != ss.ss_store_sk
    WHERE 
        ss.sold_date_sk < (SELECT MAX(ss_sold_date_sk) FROM store_sales)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT st.ss_ticket_number) AS purchased_items
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales st ON c.c_customer_sk = st.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating
),
ranked_customers AS (
    SELECT 
        ci.*,
        ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ci.purchased_items DESC) AS rank
    FROM 
        customer_info ci
)
SELECT 
    w.w_warehouse_id, 
    w.w_warehouse_name, 
    COALESCE(SUM(ss.ss_sales_price), 0) AS total_sales,
    SUM(CASE WHEN ss.ss_quantity > 5 THEN ss.ss_quantity ELSE 0 END) AS bulk_sales
FROM 
    warehouse w
LEFT JOIN 
    store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
LEFT JOIN 
    ranked_customers rc ON ss.ss_customer_sk = rc.c_customer_sk AND rc.rank <= 10
WHERE 
    w.w_country = 'USA' AND
    (substring(w.w_warehouse_name from '(\w+)$') IS NOT NULL)
GROUP BY 
    w.w_warehouse_id, w.w_warehouse_name
HAVING 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
