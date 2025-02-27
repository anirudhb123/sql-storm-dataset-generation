
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        sd.total_sales,
        sd.order_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    order_count,
    sales_rank
FROM 
    RankedCustomers
WHERE 
    sales_rank <= 10
ORDER BY 
    ca_state, total_sales DESC;
