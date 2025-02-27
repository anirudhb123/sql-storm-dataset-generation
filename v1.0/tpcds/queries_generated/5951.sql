
WITH RankedSales AS (
    SELECT 
        w.warehouse_id,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY w.warehouse_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_month_seq IN (1, 2, 3) -- First three months of 2023
    GROUP BY 
        w.warehouse_id
)
SELECT 
    r.warehouse_id,
    r.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_income_band_sk
FROM 
    RankedSales r
JOIN 
    customer c ON r.warehouse_id = (SELECT w_warehouse_id FROM warehouse WHERE w_warehouse_sk = c.c_current_addr_sk)
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.total_sales DESC;
