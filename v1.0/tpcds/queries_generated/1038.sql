
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450000 AND 2457000
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        RANK() OVER (ORDER BY total_net_paid DESC) AS customer_rank
    FROM 
        RankedSales rs
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        rs.rank = 1
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    COALESCE(MAX(ss.ss_sales_price), 0) AS max_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_sale_count
FROM 
    TopCustomers tc
LEFT JOIN 
    store_sales ss ON ss.ss_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
GROUP BY 
    tc.c_customer_id, tc.cd_gender
HAVING 
    unique_sale_count > 5 OR MAX(ss.ss_sales_price) > 100
ORDER BY 
    unique_sale_count DESC, MAX(ss.ss_sales_price) ASC;
