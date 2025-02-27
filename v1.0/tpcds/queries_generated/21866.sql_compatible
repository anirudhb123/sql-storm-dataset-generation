
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        w.w_warehouse_name,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
AddressRanked AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY LENGTH(ca.ca_street_name) DESC) AS city_rank
    FROM 
        customer_address ca
),
FinalSales AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        SUM(sd.ws_net_paid) AS total_spent,
        SUM(sd.ws_net_profit) AS total_profit,
        ar.ca_city,
        ar.ca_state
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_order_number 
    LEFT JOIN 
        AddressRanked ar ON ci.c_customer_id = ar.ca_address_id
    WHERE 
        ci.rn = 1 
        AND (ar.city_rank IS NULL OR ar.city_rank <= 5) 
        AND (ci.cd_purchase_estimate > 100 OR ci.cd_credit_rating IS NULL)
    GROUP BY 
        ci.c_customer_id, ci.c_first_name, ci.c_last_name, ar.ca_city, ar.ca_state
)
SELECT 
    fs.c_customer_id,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_spent,
    fs.total_profit,
    COALESCE(fs.ca_city, 'Unknown') AS city,
    COALESCE(fs.ca_state, 'NA') AS state,
    (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_purchase_estimate > fs.total_spent) AS relative_benchmark,
    CASE 
        WHEN fs.total_spent > 1000 THEN 'High Value'
        WHEN fs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    FinalSales fs
WHERE 
    fs.total_profit IS NOT NULL
ORDER BY 
    fs.total_spent DESC, 
    fs.c_customer_id ASC;
