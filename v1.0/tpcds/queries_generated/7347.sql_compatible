
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rs.total_sales,
        rs.order_count
    FROM 
        customer c
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name,
    COALESCE(d.d_country, 'Unknown') AS country,
    COALESCE(d.d_state, 'Unknown') AS state
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = tc.c_customer_id LIMIT 1)
LEFT JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_id)
ORDER BY 
    tc.total_sales DESC;
