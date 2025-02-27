
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(NULLIF(cd.cd_dep_count, 0), 1) AS dependent_count_adjusted
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        DATE(d.d_date) AS sale_date,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, DATE(d.d_date)
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_item_desc,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_current_price, i.i_item_desc
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    sd.sale_date,
    is.i_item_id,
    is.i_item_desc,
    is.i_current_price,
    sd.total_sales,
    sd.total_profit,
    CASE 
        WHEN sd.total_profit IS NULL THEN 'No Sales'
        WHEN sd.total_profit > 500 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_status,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY sd.total_sales DESC) AS sales_rank
FROM 
    customer_info c
JOIN 
    sales_data sd ON sd.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = c.c_customer_sk
    )
JOIN 
    item_stats is ON is.i_item_sk = sd.ws_item_sk
WHERE 
    COALESCE(c.dependent_count_adjusted, 1) > 2
ORDER BY 
    c.c_customer_sk, sd.total_sales DESC;
