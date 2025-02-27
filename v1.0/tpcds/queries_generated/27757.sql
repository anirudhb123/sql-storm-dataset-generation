
WITH AddressInfo AS (
    SELECT 
        ca.city AS city,
        ca.state AS state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        STRING_AGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, ', ') AS customer_names,
        AVG(cd.credit_rating::integer) AS average_credit_rating
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.country = 'USA'
    GROUP BY 
        ca.city, ca.state
),
SalesSummary AS (
    SELECT 
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales,
        MAX(ss.ss_sales_price) AS max_sale_price,
        MIN(ss.ss_sales_price) AS min_sale_price
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_name
),
FinalBenchmark AS (
    SELECT 
        ai.city,
        ai.state,
        ai.customer_count,
        ai.customer_names,
        ai.average_credit_rating,
        ss.total_sales,
        ss.distinct_sales,
        ss.max_sale_price,
        ss.min_sale_price
    FROM 
        AddressInfo ai
    JOIN 
        SalesSummary ss ON ai.state = 'CA'
)
SELECT 
    city,
    state,
    customer_count,
    customer_names,
    average_credit_rating,
    total_sales,
    distinct_sales,
    max_sale_price,
    min_sale_price
FROM 
    FinalBenchmark
ORDER BY 
    customer_count DESC, total_sales DESC;
