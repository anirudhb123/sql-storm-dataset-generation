
WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        CAST(1 AS INTEGER) AS level
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CAST('2002-10-01' AS DATE) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CAST('2002-10-01' AS DATE))
    UNION ALL
    SELECT 
        ih.i_item_sk,
        ih.i_item_id,
        CONCAT(ih.i_item_desc, ' - ', i.i_item_desc),
        ih.i_current_price * 0.9,  
        ih.level + 1
    FROM 
        item_hierarchy ih
    JOIN 
        item i ON ih.i_item_sk = i.i_item_sk  
    WHERE 
        ih.level < 3  
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        MAX(wb.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales wb ON c.c_customer_sk = wb.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    ch.cd_marital_status,
    ch.cd_purchase_estimate,
    ih.i_item_desc,
    ih.i_current_price,
    ch.total_spent,
    CASE 
        WHEN ch.total_spent IS NULL THEN 'No Purchases'
        WHEN ch.total_spent > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    customer_data ch
JOIN 
    item_hierarchy ih ON ch.total_spent IS NOT NULL
LEFT JOIN 
    store s ON ch.total_spent < s.s_closed_date_sk  
WHERE 
    ch.cd_gender = 'F' AND
    ch.total_spent < (SELECT AVG(total_spent) FROM customer_data)  
ORDER BY 
    ch.total_spent DESC
FETCH FIRST 100 ROWS ONLY;
