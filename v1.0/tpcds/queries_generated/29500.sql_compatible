
WITH DetailedAddressInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL AND ca.ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', ca.ca_suite_number) 
                    ELSE '' END) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PurchasingBehavior AS (
    SELECT 
        ci.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_ship_date_sk) AS last_purchase_date
    FROM 
        web_sales ws
    JOIN 
        DetailedAddressInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    GROUP BY 
        ci.c_customer_id
),
GenderedSpending AS (
    SELECT 
        cd.cd_gender,
        SUM(pb.total_spent) AS gender_total_spent,
        COUNT(pb.total_orders) AS total_orders_by_gender
    FROM 
        customer_demographics cd
    JOIN 
        PurchasingBehavior pb ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = pb.c_customer_id)
    GROUP BY 
        cd.cd_gender
)
SELECT 
    g.cd_gender AS Gender, 
    g.gender_total_spent AS Total_Spent,
    g.total_orders_by_gender AS Total_Orders 
FROM 
    GenderedSpending g
ORDER BY 
    g.gender_total_spent DESC;
