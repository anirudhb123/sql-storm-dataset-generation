
WITH sales_summary AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM dd.d_date) ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        s.s_store_id, s.s_store_name
), top_stores AS (
    SELECT 
        s_store_id,
        s_store_name,
        total_sales,
        total_transactions,
        avg_sales_price
    FROM
        sales_summary
    WHERE 
        sales_rank <= 10
)

SELECT 
    ts.s_store_id,
    ts.s_store_name,
    ts.total_sales,
    ts.total_transactions,
    ts.avg_sales_price,
    c.c_first_name,
    c.c_last_name,
    cd.cd_marital_status,
    cd.cd_gender
FROM 
    top_stores ts
JOIN 
    customer c ON c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_city = 'San Francisco')
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
ORDER BY 
    ts.total_sales DESC;
