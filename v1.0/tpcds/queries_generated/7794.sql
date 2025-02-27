
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        d.d_year,
        w.w_warehouse_name,
        s.s_store_name
    FROM 
        catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON cs.cs_ship_addr_sk = s.s_addr_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        cs.cs_item_sk, d.d_year, w.w_warehouse_name, s.s_store_name
),
TopItems AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    ti.cs_item_sk,
    ti.total_quantity,
    ti.total_sales,
    ti.total_profit,
    ti.sales_rank,
    w.w_warehouse_id,
    s.s_store_id
FROM 
    TopItems ti
JOIN warehouse w ON ti.cs_item_sk = w.w_warehouse_sk
JOIN store s ON ti.cs_item_sk = s.s_store_sk
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales DESC;
