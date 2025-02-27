
WITH customer_data AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'S'
),
product_data AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        CONCAT(i.i_item_desc, ' (', i.i_brand, ') - Price: $', CAST(i.i_current_price AS VARCHAR(10))) AS product_info
    FROM 
        item i
    WHERE 
        i.i_current_price > 50
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    pd.product_info,
    sd.ws_order_number,
    sd.ws_quantity,
    sd.ws_net_paid,
    sd.ws_net_profit
FROM 
    customer_data cd
JOIN 
    sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
JOIN 
    product_data pd ON sd.ws_item_sk = pd.i_item_sk
WHERE 
    sd.profit_rank <= 5
ORDER BY 
    cd.ca_country,
    sd.ws_order_number;
