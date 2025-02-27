
WITH ranked_sales AS (
    SELECT 
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_order_number, ws_ship_mode_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(ADDR.ca_city, 'Unknown') AS city
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ADDR ON c.c_current_addr_sk = ADDR.ca_address_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
order_summary AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.city,
    COALESCE(rs.total_sales, 0) AS total_sales,
    id.total_quantity,
    SUM(os.ws_net_profit) AS total_net_profit,
    CASE 
        WHEN ci.cd_marital_status IS NULL THEN 'Unknown' 
        ELSE ci.cd_marital_status 
    END AS marital_status
FROM 
    customer_info ci
LEFT JOIN 
    ranked_sales rs ON ci.c_customer_sk = rs.ws_order_number
JOIN 
    inventory_data id ON id.inv_item_sk = rs.ws_item_sk
LEFT JOIN 
    order_summary os ON os.ws_order_number = rs.ws_order_number AND os.profit_rank = 1
WHERE 
    ci.cd_gender = 'M' 
    AND ci.cd_purchase_estimate > 100
    AND (rs.total_sales > 500 OR id.total_quantity IS NULL)
GROUP BY 
    ci.c_first_name, ci.c_last_name, ci.city, rs.total_sales, id.total_quantity, ci.cd_marital_status
HAVING 
    SUM(os.ws_net_profit) >= 0.05 * SUM(rs.total_sales)
ORDER BY 
    total_net_profit DESC, total_sales ASC;
