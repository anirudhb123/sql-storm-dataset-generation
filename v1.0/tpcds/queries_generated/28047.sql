
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
PurchasedItems AS (
    SELECT 
        ws_bill_customer_sk,
        ARRAY_AGG(DISTINCT i.i_item_desc ORDER BY i.i_item_desc) AS purchased_items,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws_bill_customer_sk
),
Summary AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        p.purchased_items,
        p.total_orders,
        p.total_quantity
    FROM CustomerDetails cd
    LEFT JOIN PurchasedItems p ON cd.c_customer_id = p.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    purchased_items,
    total_orders,
    total_quantity,
    CASE 
        WHEN total_orders > 10 THEN 'High Volume Customer'
        WHEN total_orders BETWEEN 5 AND 10 THEN 'Medium Volume Customer'
        ELSE 'Low Volume Customer'
    END AS customer_volume_category
FROM Summary
WHERE cd_gender = 'F' 
AND cd_marital_status = 'S'
AND total_quantity > 0
ORDER BY total_quantity DESC, full_name ASC;
