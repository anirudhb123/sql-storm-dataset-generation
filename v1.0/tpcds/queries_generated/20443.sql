
WITH ranked_sales AS (
    SELECT 
        ws.sold_date_sk,
        ws.web_site_sk,
        ws.item_sk,
        ws.net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk, ws.sold_date_sk ORDER BY ws.net_profit DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.sold_date_sk) AS sales_order
    FROM 
        web_sales ws
    WHERE 
        ws.net_profit IS NOT NULL
),
top_sales AS (
    SELECT 
        sold_date_sk, 
        web_site_sk, 
        item_sk, 
        net_profit 
    FROM 
        ranked_sales 
    WHERE 
        profit_rank = 1
),
items_info AS (
    SELECT 
        i.item_sk,
        i.item_desc,
        COALESCE(i.current_price, 0) AS effective_price,
        CASE
            WHEN i.current_price IS NULL THEN 'Price not available'
            ELSE (CASE
                WHEN i.current_price < 20 THEN 'Low'
                WHEN i.current_price BETWEEN 20 AND 100 THEN 'Medium'
                ELSE 'High'
            END)
        END AS price_category
    FROM 
        item i
),
customer_info AS (
    SELECT 
        c.customer_sk,
        cd.gender,
        substring(cd.education_status from 1 for 1) AS education_initial,
        CA.city,
        CASE 
            WHEN cd.marital_status = 'S' THEN 'Single'
            WHEN cd.marital_status = 'M' THEN 'Married'
            ELSE 'Other'
        END AS marital_status_desc
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address CA ON c.current_addr_sk = CA.ca_address_sk
    WHERE 
        CASE WHEN cd.dep_count IS NULL THEN '0' ELSE cd.dep_count END < '5'
)
SELECT 
    ci.customer_sk,
    ci.gender,
    ci.education_initial,
    ci.city,
    ci.marital_status_desc,
    ti.item_desc,
    ti.effective_price,
    COALESCE(ts.net_profit, 0) AS top_profit,
    CASE 
        WHEN ti.effective_price = 0 THEN 'Free Item'
        WHEN ts.top_profit < 100 THEN 'Budget Purchase'
        ELSE 'Premium Purchase'
    END AS purchase_category
FROM 
    customer_info ci
LEFT JOIN 
    top_sales ts ON ci.customer_sk = ts.item_sk
LEFT JOIN 
    items_info ti ON ts.item_sk = ti.item_sk
WHERE 
    ci.gender = 'F' AND
    (ci.city IS NOT NULL OR ci.marital_status_desc IS NOT NULL)
ORDER BY 
    ci.city ASC, 
    ti.effective_price DESC
OFFSET 10 ROWS
FETCH NEXT 20 ROWS ONLY;
