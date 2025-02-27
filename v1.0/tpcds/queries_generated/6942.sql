
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        c.c_customer_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        AVG(ss.ss_net_paid) AS avg_net_paid
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2400 AND 2500 -- Filtering for a specific date range
    GROUP BY 
        w.w_warehouse_id, c.c_customer_id
), RankedSales AS (
    SELECT 
        warehouse_id,
        total_quantity,
        total_sales,
        transaction_count,
        avg_net_paid,
        RANK() OVER (PARTITION BY warehouse_id ORDER BY total_sales DESC) as sales_rank
    FROM 
        SalesData
)
SELECT 
    warehouse_id,
    total_quantity,
    total_sales,
    transaction_count,
    avg_net_paid,
    sales_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 10 -- Getting the top 10 customers by sales for each warehouse
ORDER BY 
    warehouse_id, sales_rank;
