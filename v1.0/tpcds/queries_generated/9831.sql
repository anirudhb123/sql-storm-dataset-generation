
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.w_warehouse_id
),
TopSales AS (
    SELECT 
        warehouse_id, 
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    ts.warehouse_id, 
    ts.total_sales, 
    cd.cd_gender,
    COUNT(c.c_customer_sk) AS num_customers
FROM 
    TopSales ts
JOIN 
    web_sales ws ON ts.warehouse_id = ws.ws_warehouse_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ts.warehouse_id, ts.total_sales, cd.cd_gender
ORDER BY 
    ts.total_sales DESC, 
    cd.cd_gender;
