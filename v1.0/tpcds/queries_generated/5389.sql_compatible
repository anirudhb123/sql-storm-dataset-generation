
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        c.c_customer_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        w.w_warehouse_id, c.c_customer_id, d.d_year, d.d_month_seq
),
MonthlyPerformance AS (
    SELECT 
        year,
        month,
        COUNT(DISTINCT customer_id) AS customer_count,
        COUNT(*) AS transaction_count,
        AVG(total_sales) AS avg_sales_per_customer,
        AVG(total_profit) AS avg_profit_per_customer
    FROM (
        SELECT 
            d.d_year AS year,
            d.d_month_seq AS month,
            w.w_warehouse_id AS warehouse_id,
            c.c_customer_id,
            SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit
        FROM 
            web_sales ws
        JOIN 
            warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN 
            customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN 
            date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY 
            d.d_year, d.d_month_seq, w.w_warehouse_id, c.c_customer_id
    ) AS MonthlySales
    GROUP BY 
        year, month
),
PerformanceBenchmark AS (
    SELECT 
        year,
        month,
        customer_count,
        transaction_count,
        avg_sales_per_customer,
        avg_profit_per_customer,
        RANK() OVER (ORDER BY avg_sales_per_customer DESC) AS sales_rank,
        RANK() OVER (ORDER BY avg_profit_per_customer DESC) AS profit_rank
    FROM 
        MonthlyPerformance
)
SELECT 
    year,
    month,
    customer_count,
    transaction_count,
    avg_sales_per_customer,
    avg_profit_per_customer,
    sales_rank,
    profit_rank
FROM 
    PerformanceBenchmark
ORDER BY 
    year DESC, month DESC;
