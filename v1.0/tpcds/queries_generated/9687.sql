
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_tax,
        RANK() OVER (PARTITION BY sd.d_year ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    ti.total_tax,
    i.i_item_desc,
    i.i_brand,
    i.i_category
FROM 
    TopItems ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales DESC;
