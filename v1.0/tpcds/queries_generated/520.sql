
WITH TotalSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        td.d_year,
        CASE 
            WHEN td.d_year < 2020 THEN 'Before 2020' 
            ELSE '2020 and After' 
        END AS period,
        T.total_spent,
        T.total_orders,
        RANK() OVER (PARTITION BY period ORDER BY total_spent DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TotalSales T ON c.c_customer_sk = T.customer_sk
    JOIN 
        date_dim td ON c.c_first_sales_date_sk = td.d_date_sk
    WHERE 
        cd.cd_gender IS NOT NULL
), TopCustomers AS (
    SELECT 
        c_first_name,
        c_last_name,
        total_spent,
        total_orders,
        spending_rank
    FROM 
        CustomerStats
    WHERE 
        spending_rank <= 10
    ORDER BY 
        period, spending_rank
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_orders,
    CASE 
        WHEN tc.total_orders > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS buyer_type
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_address ca ON tc.customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IS NOT NULL 
    AND ca.ca_country = 'USA'
ORDER BY 
    tc.total_spent DESC;
