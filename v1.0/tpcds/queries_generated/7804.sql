
WITH SalesData AS (
    SELECT 
        ws.web_site_sk, 
        ws.web_name, 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_sales_price) AS total_sales_amount 
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk 
    GROUP BY 
        ws.web_site_sk, ws.web_name, d.d_year, d.d_month_seq
),
SalesRanked AS (
    SELECT 
        web_site_sk, 
        web_name, 
        d_year, 
        d_month_seq, 
        total_quantity_sold, 
        total_sales_amount, 
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales_amount DESC) AS sales_rank 
    FROM 
        SalesData
)
SELECT 
    sr.web_name, 
    sr.d_year, 
    sr.d_month_seq, 
    sr.total_quantity_sold, 
    sr.total_sales_amount 
FROM 
    SalesRanked sr 
WHERE 
    sr.sales_rank <= 5 
ORDER BY 
    sr.d_year, sr.d_month_seq, sr.total_sales_amount DESC;
