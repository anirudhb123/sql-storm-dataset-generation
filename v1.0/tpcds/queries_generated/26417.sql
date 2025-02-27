
WITH Address_Frequency AS (
    SELECT ca_city, COUNT(*) AS address_count
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY', 'TX')
    GROUP BY ca_city
    HAVING COUNT(*) > 10
),
Customer_Info AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city IN (SELECT ca_city FROM Address_Frequency)
),
Demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ci.c_customer_id
    FROM customer_demographics cd
    JOIN Customer_Info ci ON ci.c_customer_id = cd.cd_demo_sk
),
Sales_Summary AS (
    SELECT 
        ci.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM web_sales ws
    JOIN Customer_Info ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    GROUP BY ci.c_customer_id
)

SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    d.cd_gender,
    d.cd_marital_status,
    ss.total_sales,
    ss.total_orders,
    ss.last_purchase_date
FROM Customer_Info ci
JOIN Demographics d ON ci.c_customer_id = d.c_customer_id
JOIN Sales_Summary ss ON ci.c_customer_id = ss.c_customer_id
WHERE ss.total_sales > 1000
ORDER BY ss.total_sales DESC;
