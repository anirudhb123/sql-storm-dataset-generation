
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_dep_count,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'S' -- filtering for single customers

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_dep_count,
        ch.level + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON c.c_customer_sk = ch.c_customer_sk + 1 -- Hypothetical next customer
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_dep_count > 0
),

active_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),

inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)

SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.c_birth_year,
    ch.cd_gender,
    ch.level,
    COALESCE(as.total_sales, 0) AS total_sales,
    COALESCE(as.avg_sales_price, 0.00) AS avg_sales_price,
    COALESCE(is.total_stock, 0) AS total_stock,
    CASE 
        WHEN COALESCE(as.total_sales, 0) > (SELECT AVG(total_sales) FROM active_sales) THEN 'High Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    customer_hierarchy ch
LEFT JOIN 
    active_sales as ON ch.c_customer_sk = as.ws_item_sk
LEFT JOIN 
    inventory_status is ON ch.c_customer_sk = is.inv_item_sk
WHERE 
    ch.c_birth_year > 1990
ORDER BY 
    ch.c_last_name, 
    ch.c_first_name;
