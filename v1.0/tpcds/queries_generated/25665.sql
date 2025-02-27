
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AggregateSales AS (
    SELECT
        ci.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    JOIN CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY ci.c_customer_sk
),
RankedCustomers AS (
    SELECT
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        as.total_orders,
        as.total_sales,
        ROW_NUMBER() OVER (ORDER BY as.total_sales DESC) AS rank
    FROM CustomerInfo ci
    JOIN AggregateSales as ON ci.c_customer_sk = as.c_customer_sk
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.ca_city,
    rc.ca_state,
    rc.ca_country,
    rc.total_orders,
    rc.total_sales,
    rc.rank,
    CASE 
        WHEN rc.total_sales >= 1000 THEN 'High Value'
        WHEN rc.total_sales >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM RankedCustomers rc
WHERE rc.rank <= 100;
