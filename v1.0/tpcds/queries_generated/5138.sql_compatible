
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.net_paid) AS total_sales
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    t.c_customer_sk, 
    t.c_first_name, 
    t.c_last_name, 
    t.total_sales, 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers AS t
JOIN 
    customer_demographics AS cd ON t.c_customer_sk = cd.cd_demo_sk
JOIN 
    customer_address AS ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer AS c WHERE c.c_customer_sk = t.c_customer_sk)
WHERE 
    sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
