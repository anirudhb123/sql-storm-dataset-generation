
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        (SELECT c_customer_id AS customer_id FROM customer WHERE c_preferred_cust_flag = 'Y') AS c
    JOIN 
        CustomerSales cs ON c.customer_id = cs.c_customer_id
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS customer_count,
        SUM(tc.total_sales) AS demographic_sales
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON tc.customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    sbd.cd_gender,
    sbd.customer_count,
    sbd.demographic_sales,
    ROUND(sbd.demographic_sales / NULLIF(sbd.customer_count, 0), 2) AS avg_sales_per_customer
FROM 
    SalesByDemographics sbd
ORDER BY 
    sbd.demographic_sales DESC;
