
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_count AS (
    SELECT 
        c_current_cdemo_sk,
        COUNT(DISTINCT c_customer_sk) AS num_customers
    FROM 
        customer
    WHERE 
        c_birth_month = 12 OR c_birth_month = 6
    GROUP BY 
        c_current_cdemo_sk
),
item_inventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS available_quantity
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv_item_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(CASE 
        WHEN COALESCE(i.i_item_desc, '') = '' THEN NULL 
        ELSE 1 
    END) AS valid_items,
    SUM(i.i_current_price * (1 - COALESCE(pr.p_discount_active, '0'))) AS total_revenue,
    MAX(i.i_current_price) AS max_price,
    MIN(i.i_current_price) AS min_price,
    AVG(i.i_current_price) AS avg_price,
    SUM(CASE
        WHEN r.r_reason_desc = 'Customer Dissatisfaction' THEN sr_return_quantity
        ELSE 0
    END) AS dissatisfaction_returns
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store s ON c.c_customer_sk = s.s_store_sk
LEFT JOIN 
    item i ON i.i_item_sk = (SELECT ws_item_sk FROM ranked_sales WHERE sales_rank = 1)
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    promotion pr ON pr.p_item_sk = i.i_item_sk
LEFT JOIN 
    reason r ON r.r_reason_sk = sr.sr_reason_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND (cd.cd_gender = 'F' OR cd.cd_gender = 'M')
    AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
    AND (SELECT COUNT(*) FROM item_inventory WHERE inv_item_sk = i.i_item_sk) > 0
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_revenue DESC;
