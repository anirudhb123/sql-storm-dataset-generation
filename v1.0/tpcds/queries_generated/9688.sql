
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        w.w_warehouse_id, d.d_year, d.d_month_seq
),
TopSales AS (
    SELECT 
        warehouse_id,
        d_year,
        d_month_seq,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    ts.warehouse_id,
    ts.d_year,
    ts.d_month_seq,
    ts.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    TopSales ts
JOIN 
    customer c ON ts.warehouse_id = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
ORDER BY 
    ts.total_sales DESC, ts.warehouse_id, ts.d_year, ts.d_month_seq;
