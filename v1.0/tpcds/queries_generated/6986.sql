
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_order_number,
        ws.sales_price,
        ws.quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
),
TopSales AS (
    SELECT 
        web_site_id,
        SUM(sales_price * quantity) AS total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        web_site_id
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    JOIN 
        store st ON ss.ss_store_sk = st.s_store_sk
    JOIN 
        warehouse w ON st.s_company_id = w.w_warehouse_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT dd.d_date_sk FROM date_dim dd WHERE dd.d_year = 2022)
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    ws.w_warehouse_id,
    ws.total_store_sales
FROM 
    TopSales ts
JOIN 
    WarehouseSales ws ON ts.web_site_id = ws.w_warehouse_id
ORDER BY 
    total_sales DESC, total_store_sales DESC
LIMIT 100;
