
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders
    FROM 
        high_value_customers c
    WHERE 
        sales_rank <= 10
),
customer_details AS (
    SELECT 
        cu.c_customer_sk,
        cu.c_first_name,
        cu.c_last_name,
        ca.ca_city,
        ca.ca_state,
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        top_customers cu
    JOIN 
        customer_address ca ON ca.ca_address_sk = cu.c_customer_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = cu.c_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        cu.c_customer_sk, cu.c_first_name, cu.c_last_name, ca.ca_city, ca.ca_state, d.d_date
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    cd.total_sales,
    CASE 
        WHEN cd.total_sales IS NULL THEN 'No Sales'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    customer_details cd
LEFT JOIN 
    household_demographics hd ON hd.hd_demo_sk = cd.c_customer_sk
WHERE 
    (hd.hd_income_band_sk IS NULL OR hd.hd_income_band_sk IN 
        (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 50000))
ORDER BY 
    cd.total_sales DESC;
