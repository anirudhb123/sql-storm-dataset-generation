
WITH FilteredCustomers AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address, cd.cd_gender, cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
CustomerAddresses AS (
    SELECT ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_zip
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('NY', 'CA')
),
SalesData AS (
    SELECT ws.ws_order_number, ws.ws_item_sk, ws.ws_quantity, ws.ws_sales_price, 
           i.i_item_desc, i.i_product_name
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_quantity > 5
),
AggregatedSales AS (
    SELECT cs.c_customer_id, COUNT(*) as total_orders, SUM(sd.ws_sales_price * sd.ws_quantity) AS total_spent
    FROM FilteredCustomers cs
    JOIN SalesData sd ON cs.c_customer_id = sd.ws_order_number
    GROUP BY cs.c_customer_id
)
SELECT fc.c_first_name, fc.c_last_name, ca.ca_city, ca.ca_state, 
       asales.total_orders, asales.total_spent
FROM FilteredCustomers fc
JOIN CustomerAddresses ca ON fc.c_customer_id = ca.ca_address_id
JOIN AggregatedSales asales ON fc.c_customer_id = asales.c_customer_id
ORDER BY asales.total_spent DESC
LIMIT 10;
