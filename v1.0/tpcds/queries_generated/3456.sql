
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 10000
    GROUP BY 
        ws.ws_item_sk
), customer_stats AS (
    SELECT 
        c.c_customer_sk,
        d.d_year,
        cd.cd_gender,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COUNT(DISTINCT cd.cd_demo_sk) AS demographics_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, d.d_year, cd.cd_gender
), inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ss.total_quantity,
    ss.total_net_paid,
    cs.c_customer_sk,
    cs.d_year,
    cs.cd_gender,
    cs.max_purchase_estimate,
    cs.demographics_count,
    is.total_inventory,
    COALESCE(is.total_inventory, 0) AS inventory_not_null,
    CASE 
        WHEN ss.total_quantity IS NULL THEN 'No Sales'
        ELSE 'Sales Present' 
    END AS sales_status
FROM 
    item i
LEFT JOIN 
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    customer_stats cs ON cs.d_year = 2023
LEFT JOIN 
    inventory_status is ON i.i_item_sk = is.inv_item_sk
WHERE 
    i.i_current_price > 20
    AND (cs.demographics_count > 0 OR inventory_not_null > 5)
ORDER BY 
    ss.total_net_paid DESC NULLS LAST, 
    is.total_inventory DESC;
