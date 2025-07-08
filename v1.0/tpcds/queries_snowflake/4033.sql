
WITH SalesData AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2022
    GROUP BY 
        d.d_year, d.d_month_seq, i.i_category
),
TopSales AS (
    SELECT 
        d_year, d_month_seq, i_category, total_quantity, total_sales
    FROM 
        SalesData
    WHERE 
        sales_rank <= 10
)
SELECT 
    ts.d_year,
    ts.d_month_seq,
    ts.i_category,
    COALESCE(ts.total_quantity, 0) AS quantity,
    COALESCE(ts.total_sales, 0) AS sales,
    COALESCE(ts.total_sales / NULLIF(ts.total_quantity, 0), 0) AS average_sales_per_item
FROM 
    TopSales ts
FULL OUTER JOIN 
    warehouse w ON w.w_warehouse_sk = (
        SELECT 
            inv.inv_warehouse_sk 
        FROM 
            inventory inv 
        WHERE 
            inv.inv_date_sk = (
                SELECT MAX(inv2.inv_date_sk) 
                FROM inventory inv2 
                WHERE inv2.inv_item_sk = (SELECT i_item_sk FROM item WHERE i_category = ts.i_category LIMIT 1)
            ) 
        LIMIT 1
    )
ORDER BY 
    ts.d_year, ts.d_month_seq, ts.i_category;
