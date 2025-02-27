
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER(PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk
), top_sales AS (
    SELECT 
        sd.ss_store_sk,
        sd.ss_item_sk,
        sd.total_quantity,
        sd.total_net_paid
    FROM 
        sales_data sd
    WHERE 
        sd.rank <= 5
), item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(NULLIF(i.i_item_desc, ''), 'Unknown') AS item_description
    FROM 
        item i
), customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        SUM(COALESCE(cd.cd_dep_count, 0)) AS total_dependents,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    sd.ss_store_sk,
    id.item_description,
    sd.total_quantity,
    sd.total_net_paid,
    cs.unique_customers,
    cs.total_dependents,
    cs.max_purchase_estimate
FROM 
    top_sales sd
JOIN 
    item_details id ON sd.ss_item_sk = id.i_item_sk
JOIN 
    customer_stats cs ON cs.c_customer_sk = (SELECT c.c_customer_sk 
                                             FROM store s 
                                             JOIN customer c ON c.c_current_addr_sk = s.s_store_sk 
                                             WHERE s.s_store_sk = sd.ss_store_sk 
                                             LIMIT 1) 
ORDER BY 
    sd.ss_store_sk, sd.total_net_paid DESC
LIMIT 100;
