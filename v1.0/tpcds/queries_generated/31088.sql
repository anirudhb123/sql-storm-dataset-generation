
WITH RECURSIVE sales_totals AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ws_item_sk
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    
    UNION ALL
    
    SELECT 
        c.cs_sold_date_sk,
        SUM(c.cs_ext_sales_price) AS total_sales,
        c.cs_item_sk
    FROM 
        catalog_sales AS c
    JOIN sales_totals AS st ON c.cs_sold_date_sk = st.ws_sold_date_sk AND c.cs_item_sk = st.ws_item_sk
    GROUP BY 
        c.cs_sold_date_sk, c.cs_item_sk
),
inventory_status AS (
    SELECT 
        inv.inv_quantity_on_hand,
        itm.i_item_id,
        itm.i_product_name,
        itm.i_current_price
    FROM 
        inventory inv
    JOIN item itm ON inv.inv_item_sk = itm.i_item_sk
    WHERE 
        inv.inv_quantity_on_hand < 50
),
customer_summary AS (
    SELECT 
        cu.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer cu
    LEFT JOIN 
        web_sales ws ON cu.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cu.c_customer_sk, cd.cd_gender
),
ranked_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_summary cs
)
SELECT 
    r.c_customer_sk,
    r.cd_gender,
    r.total_spent,
    r.order_count,
    inv.i_item_id,
    inv.i_product_name,
    inv.i_current_price,
    COALESCE(st.total_sales, 0) AS total_online_sales
FROM 
    ranked_customers r
LEFT JOIN 
    inventory_status inv ON r.total_spent > inv.i_current_price * 5
LEFT JOIN 
    sales_totals st ON r.c_customer_sk = st.ws_item_sk
WHERE 
    r.rank <= 10 
ORDER BY 
    r.cd_gender, r.total_spent DESC;
