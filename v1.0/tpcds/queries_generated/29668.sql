
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_country AS country,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_ext_ship_cost) AS total_shipping_cost,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSalesInfo AS (
    SELECT 
        ci.customer_id,
        ci.full_name,
        ci.city,
        ci.state,
        ci.country,
        ci.gender,
        ci.marital_status,
        ss.total_sales,
        ss.order_count,
        ss.total_shipping_cost,
        ss.total_net_profit
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesSummary ss ON ci.customer_id = ss.customer_id
)
SELECT 
    customer_id,
    full_name,
    city,
    state,
    country,
    gender,
    marital_status,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    COALESCE(total_shipping_cost, 0) AS total_shipping_cost,
    COALESCE(total_net_profit, 0) AS total_net_profit,
    CONCAT('Total Sales: $', FORMAT(COALESCE(total_sales, 0), 2)) AS formatted_sales,
    CONCAT('Orders: ', COALESCE(order_count, 0)) AS formatted_orders
FROM 
    CustomerSalesInfo
ORDER BY 
    total_sales DESC
LIMIT 10;
