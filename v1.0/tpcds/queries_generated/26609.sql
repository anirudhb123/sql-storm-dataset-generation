
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
popular_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        total_sold DESC
    LIMIT 10
),
order_summary AS (
    SELECT 
        ws.ws_order_number,
        ci.full_name,
        pi.i_item_desc,
        SUM(ws.ws_quantity) AS quantity_sold,
        SUM(ws.ws_net_paid) AS total_amount
    FROM 
        web_sales ws
    JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        popular_items pi ON ws.ws_item_sk = pi.i_item_id
    GROUP BY 
        ws.ws_order_number, ci.full_name, pi.i_item_desc
)
SELECT 
    os.ws_order_number,
    os.full_name,
    os.i_item_desc,
    os.quantity_sold,
    os.total_amount,
    DENSE_RANK() OVER (PARTITION BY os.full_name ORDER BY os.total_amount DESC) AS sales_rank
FROM 
    order_summary os
WHERE 
    os.total_amount > 100
ORDER BY 
    os.full_name, sales_rank;
