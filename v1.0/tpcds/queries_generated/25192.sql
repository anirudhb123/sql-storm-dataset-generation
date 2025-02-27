
WITH Address_Components AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS address_rank
    FROM customer_address
), 
Customer_Info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ac.ca_city,
        ac.ca_state,
        ac.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN Address_Components ac ON c.c_current_addr_sk = ac.ca_address_sk
), 
Sales_Data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state
    FROM web_sales ws
    JOIN Customer_Info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
)
SELECT 
    ci.ca_city,
    ci.ca_state,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    SUM(sd.ws_sales_price) AS total_sales,
    AVG(sd.ws_net_profit) AS avg_net_profit
FROM Sales_Data sd
JOIN Customer_Info ci ON sd.c_first_name = ci.c_first_name AND sd.c_last_name = ci.c_last_name
GROUP BY ci.ca_city, ci.ca_state
HAVING COUNT(DISTINCT sd.ws_order_number) > 10
ORDER BY ci.ca_state, ci.ca_city;
