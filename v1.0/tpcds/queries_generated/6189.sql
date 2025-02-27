
WITH RankedSales AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(ss.ss_item_sk) AS total_items_sold,
        SUM(ss.ss_net_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss.ss_store_sk ORDER BY SUM(ss.ss_net_sales_price) DESC) AS rank
    FROM 
        store_sales ss
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        dd.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ss.ss_store_sk
),
TopStores AS (
    SELECT 
        rs.ss_store_sk,
        rs.total_items_sold,
        rs.total_sales,
        s.s_store_name,
        s.s_city,
        s.s_state
    FROM 
        RankedSales rs
    JOIN 
        store s ON rs.ss_store_sk = s.s_store_sk
    WHERE 
        rs.rank <= 10
)
SELECT 
    ts.s_store_name,
    ts.s_city,
    ts.s_state,
    ts.total_items_sold,
    ts.total_sales,
    ROUND(ts.total_sales / NULLIF(ts.total_items_sold, 0), 2) AS avg_sales_per_item
FROM 
    TopStores ts
ORDER BY 
    ts.total_sales DESC;
