
WITH RECURSIVE sales_data AS (
    SELECT 
        s_store_sk,
        ss_item_sk,
        ss_net_paid,
        ss_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY ss_sold_date_sk DESC) AS rn
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT 
        s_store_sk,
        ss_item_sk,
        ss_net_paid * 1.1 AS ss_net_paid,  -- Simulating an increase for the next year
        ss_sold_date_sk + 365 AS ss_sold_date_sk,
        rn + 1
    FROM 
        sales_data
    WHERE 
        rn < 12  -- Limit to 12 months
)
SELECT 
    c.c_customer_id,
    SUM(sd.ss_net_paid) AS total_spent,
    COUNT(DISTINCT sd.ss_item_sk) AS unique_items_bought,
    MAX(d.d_date) AS last_purchase_date,
    AVG(sd.ss_net_paid) OVER (PARTITION BY c.c_customer_id) AS avg_spent_per_transaction,
    CASE 
        WHEN COUNT(DISTINCT wd.wp_web_page_sk) > 10 THEN 'Frequent Visitor'
        ELSE 'Occasional Visitor'
    END AS visitor_category
FROM 
    customer c
LEFT JOIN 
    sales_data sd ON c.c_customer_sk = sd.s_store_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_page wd ON ws.ws_web_page_sk = wd.wp_web_page_sk
LEFT JOIN 
    date_dim d ON sd.ss_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year < (EXTRACT(YEAR FROM CURRENT_DATE) - 18)  -- Customers over 18 years old
    AND sd.ss_net_paid IS NOT NULL
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_spent DESC 
LIMIT 100;
