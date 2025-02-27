
WITH RECURSIVE cte_sales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        RANK() OVER (ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
),
cte_customer AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        c.c_first_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws_ext_sales_price) DESC) AS gender_rank
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        (cd.cd_marital_status IS NOT NULL AND cd.cd_gender IS NOT NULL)
    GROUP BY 
        c.c_customer_sk, c.c_last_name, c.c_first_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
cte_inventory AS (
    SELECT 
        inv.warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(inv.inv_item_sk) AS unique_items
    FROM 
        inventory inv
    GROUP BY 
        inv.warehouse_sk
)
SELECT 
    cs.total_sales,
    cs.total_transactions,
    cc.c_last_name,
    cc.c_first_name,
    cc.order_count,
    cc.total_spent,
    ci.total_inventory,
    ci.unique_items
FROM 
    cte_sales cs
JOIN 
    cte_customer cc ON cc.order_count > 0
JOIN 
    cte_inventory ci ON cs.ss_store_sk = ci.warehouse_sk
WHERE 
    (cc.total_spent > 1000 OR cc.gender_rank <= 5)
ORDER BY 
    cs.total_sales DESC, cc.total_spent DESC
LIMIT 100;
