
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c_customer_sk,
        c_current_addr_sk,
        cd_demo_sk,
        cd_marital_status,
        cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY c_birth_year DESC) AS rank
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
inventory_check AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS available_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
top_items AS (
    SELECT 
        ws_item_sk,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS item_rank
    FROM 
        sales_summary
)
SELECT 
    ci.c_customer_sk,
    ci.cd_marital_status,
    ci.cd_gender,
    ts.ws_item_sk,
    SUM(ss.total_quantity) AS total_quantity_sold,
    SUM(ss.total_sales) AS total_sales_amount,
    COALESCE(ic.available_inventory, 0) AS current_inventory
FROM 
    sales_summary ss
JOIN 
    top_items ts ON ss.ws_item_sk = ts.ws_item_sk AND ts.item_rank <= 10
JOIN 
    customer_info ci ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    inventory_check ic ON ic.inv_item_sk = ss.ws_item_sk
WHERE 
    ci.cd_marital_status = 'M' 
    AND (ci.cd_gender = 'F' OR ci.cd_gender IS NULL)
GROUP BY 
    ci.c_customer_sk, ci.cd_marital_status, ci.cd_gender, ts.ws_item_sk
ORDER BY 
    total_sales_amount DESC;
