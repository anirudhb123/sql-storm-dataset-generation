
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_item_sk) AS item_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM web_sales ws
    GROUP BY ws.ws_order_number, ws.ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        si.total_sales,
        si.item_count,
        si.last_purchase_date,
        RANK() OVER (PARTITION BY ci.ca_city ORDER BY si.total_sales DESC) AS sales_rank
    FROM CustomerInfo ci
    JOIN SalesData si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_sales,
    item_count,
    last_purchase_date,
    sales_rank
FROM RankedCustomers
WHERE sales_rank <= 10
ORDER BY ca_city, total_sales DESC;
