
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                FROM date_dim 
                                WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    tc.c_customer_sk,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name,
    tc.total_sales,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.total_sales < 100 THEN 'Low Sales'
        WHEN tc.total_sales BETWEEN 100 AND 500 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;

-- Join with a correlated subquery to fetch their primary address and demo details
SELECT 
    cs.c_customer_sk,
    cs.full_name,
    cs.total_sales,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    (SELECT 
        tc.c_customer_sk,
        CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name,
        tc.total_sales
    FROM 
        TopCustomers tc) cs
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk 
                                                FROM customer 
                                                WHERE c_customer_sk = cs.c_customer_sk)
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk 
                                                  FROM customer 
                                                  WHERE c_customer_sk = cs.c_customer_sk)
ORDER BY 
    cs.total_sales DESC;
