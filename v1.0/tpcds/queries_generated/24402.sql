
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_birth_year,
        c.c_current_addr_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_quantity,
        ws_ws_ship_date_sk,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS profit_last_week,
        COUNT(DISTINCT ws.ws_order_number) OVER (PARTITION BY ws.ws_item_sk) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20000101 AND 20231231
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        COALESCE(COUNT(DISTINCT i.i_item_sk), 0) AS item_count
    FROM 
        warehouse w
    LEFT JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        w.w_warehouse_id, w.w_warehouse_name, w.w_city, w.w_state
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    CASE 
        WHEN ci.cd_gender = 'F' THEN 'Female'
        WHEN ci.cd_gender = 'M' THEN 'Male'
        ELSE 'Undefined'
    END AS gender_full,
    CASE 
        WHEN ws.ws_quantity > 0 THEN 'Purchased'
        ELSE 'Not Purchased'
    END AS purchase_status,
    wi.item_count,
    sd.profit_last_week,
    sd.total_orders,
    
    CASE 
        WHEN sd.profit_last_week IS NULL THEN 'No profits recorded'
        WHEN sd.profit_last_week < 0 THEN 'Losses incurred'
        ELSE 'Profit recorded'
    END AS profit_status,
    
    (SELECT COUNT(*)
     FROM store s
     WHERE s.s_state = wi.w_state) AS store_count_in_state,

    (SELECT MAX(d.d_year)
     FROM date_dim d
     WHERE d.d_date BETWEEN '2000-01-01' AND CURRENT_DATE) AS max_year_recorded

FROM 
    customer_info ci
LEFT JOIN 
    sales_data sd ON ci.c_customer_id = sd.ws_item_sk
JOIN 
    warehouse_info wi ON ci.c_current_addr_sk = wi.item_count
WHERE 
    ci.rn = 1
  AND 
    (ci.c_birth_year BETWEEN 1960 AND EXTRACT(YEAR FROM CURRENT_DATE) OR ci.cd_marital_status IS NULL)
ORDER BY 
    ci.c_customer_id;
