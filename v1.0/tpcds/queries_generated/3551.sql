
WITH RecursiveSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_year = 2023)
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(rs.ws_order_number) AS total_orders,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        RecursiveSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_orders,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'High Value'
            WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        CustomerStats cs
)

SELECT 
    c.ca_city,
    c.ca_state,
    COUNT(DISTINCT ss.c_customer_sk) AS num_customers,
    SUM(ss.total_spent) AS total_sales,
    AVG(ss.total_orders) AS avg_orders_per_customer
FROM 
    customer_address c
JOIN 
    customer cs ON c.ca_address_sk = cs.c_current_addr_sk
JOIN 
    SalesSummary ss ON cs.c_customer_sk = ss.c_customer_sk
GROUP BY 
    c.ca_city, c.ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;

