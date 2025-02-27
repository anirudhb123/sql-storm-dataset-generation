
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_id
    GROUP BY 
        c.c_customer_id
),
Ranking AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        RANK() OVER (PARTITION BY ci.ca_state ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_id = sd.c_customer_id
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_quantity,
    total_sales,
    order_count,
    sales_rank
FROM 
    Ranking
WHERE 
    sales_rank <= 5
ORDER BY 
    ca_state, sales_rank;
