
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2022
),
AggregateSales AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_item_sk) AS item_count
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq
)
SELECT 
    as.d_year,
    as.d_month_seq,
    as.total_quantity,
    as.total_sales,
    as.item_count,
    RANK() OVER (PARTITION BY as.d_year ORDER BY as.total_sales DESC) AS sales_rank
FROM 
    AggregateSales AS as
WHERE 
    as.total_quantity > 1000
ORDER BY 
    as.d_year, as.d_month_seq;
