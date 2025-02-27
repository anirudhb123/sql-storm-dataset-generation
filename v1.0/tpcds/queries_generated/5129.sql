
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458290 AND 2458380   -- assuming date range for the last 30 days in Julian format
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_sales,
        r.total_orders
    FROM 
        RankedSales r
    JOIN 
        customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        r.sales_rank <= 100  -- Top 100 customers
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    cdem.cd_gender,
    cdem.cd_marital_status,
    cdem.cd_purchase_estimate,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_demographics cdem ON tc.ws_bill_customer_sk = cdem.cd_demo_sk
LEFT JOIN 
    customer_address ca ON tc.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    tc.total_sales DESC;
