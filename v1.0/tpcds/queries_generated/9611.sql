
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        d.d_year AS sale_year,
        d.d_month_seq AS sale_month
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        ws.web_site_id, i.i_item_id, d.d_year, d.d_month_seq
),
ranked_sales AS (
    SELECT 
        web_site_id,
        i_item_id,
        total_quantity,
        total_sales,
        sale_year,
        sale_month,
        RANK() OVER (PARTITION BY web_site_id ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    rs.web_site_id,
    rs.i_item_id,
    rs.total_quantity,
    rs.total_sales,
    rs.sale_year,
    rs.sale_month
FROM 
    ranked_sales rs
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    rs.web_site_id, rs.total_sales DESC;
