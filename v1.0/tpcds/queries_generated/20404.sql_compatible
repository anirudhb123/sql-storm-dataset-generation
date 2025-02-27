
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 
        AND (ws.ws_ext_sales_price / NULLIF(ws.ws_quantity, 0)) > 100
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ROW_NUMBER() OVER (ORDER BY ci.total_spent DESC) AS customer_rank
    FROM 
        customer_info ci
    WHERE 
        ci.total_orders > 5 AND ci.total_spent > 500
),
inventory_stats AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
popular_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_current_price
    HAVING 
        COUNT(ws.ws_order_number) > 10
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    pi.i_item_desc,
    pi.order_count,
    is.total_inventory,
    rs.ws_sales_price,
    COALESCE(rs.sales_rank, 0) AS sales_rank
FROM 
    high_value_customers hvc
JOIN 
    popular_items pi ON pi.i_item_sk IN (
        SELECT 
            i.i_item_sk 
        FROM 
            inventory_stats is
        JOIN 
            item i ON is.inv_item_sk = i.i_item_sk
        WHERE 
            is.total_inventory > 0
    )
LEFT JOIN 
    ranked_sales rs ON hvc.c_customer_sk = rs.web_site_sk
WHERE 
    (hvc.c_first_name IS NOT NULL OR hvc.c_last_name IS NOT NULL)
    AND NOT EXISTS (
        SELECT 1 
        FROM catalog_sales cs
        WHERE cs.cs_item_sk = pi.i_item_sk
        AND cs.cs_sales_price < pi.i_current_price
    )
ORDER BY 
    hvc.c_last_name, hvc.c_first_name, pi.order_count DESC;
