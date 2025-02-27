
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        MAX(ss.ss_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year < 1980 
        AND c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
Sales_Rank AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        CASE
            WHEN cs.total_sales >= 1000 THEN 'High Value'
            WHEN cs.total_sales BETWEEN 500 AND 999 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_category
    FROM 
        Customer_Sales cs
)
SELECT 
    sr.c_customer_id,
    sr.total_sales,
    sr.sales_rank,
    sr.customer_category,
    ca.ca_city,
    ca.ca_state
FROM 
    Sales_Rank sr
JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT 
            c.c_current_addr_sk 
        FROM 
            customer c 
        WHERE 
            c.c_customer_id = sr.c_customer_id
    )
LEFT JOIN 
    store_returns r ON r.sr_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = sr.c_customer_id)
WHERE 
    sr.sales_rank <= 10 
    OR (sr.customer_category = 'Low Value' AND r.sr_returned_date_sk IS NOT NULL)
ORDER BY 
    sr.sales_rank, ca.ca_city;
