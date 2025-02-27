
WITH CustomerInfo AS (
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
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateSales AS (
    SELECT 
        ci.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        CustomerInfo ci
    JOIN 
        web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_id
),
RankedCustomers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        a.total_orders,
        a.total_spent,
        RANK() OVER (ORDER BY a.total_spent DESC) AS revenue_rank
    FROM 
        CustomerInfo ci
    JOIN 
        AggregateSales a ON ci.c_customer_id = a.c_customer_id
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_orders,
    total_spent,
    revenue_rank
FROM 
    RankedCustomers
WHERE 
    revenue_rank <= 10
ORDER BY 
    total_spent DESC;
