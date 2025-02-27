
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_transactions,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    cc.cc_name AS call_center_name,
    COUNT(DISTINCT tc.c_customer_sk) AS number_of_top_customers,
    AVG(tc.total_sales) AS avg_top_customer_sales
FROM 
    call_center cc
JOIN 
    TopCustomers tc ON cc.cc_call_center_sk = (
        SELECT 
            cc2.cc_call_center_sk 
        FROM 
            store s
        JOIN 
            store_sales ss ON s.s_store_sk = ss.ss_store_sk
        JOIN 
            customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN 
            customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        WHERE 
            cd.cd_gender = 'F' AND 
            ss.ss_sold_date_sk BETWEEN 2458504 AND 2458505  -- Arbitrary date range
        GROUP BY 
            cc2.cc_call_center_sk 
        ORDER BY 
            SUM(ss.ss_net_paid) DESC
        LIMIT 1
    )
GROUP BY 
    cc.cc_name
ORDER BY 
    number_of_top_customers DESC
LIMIT 10;
