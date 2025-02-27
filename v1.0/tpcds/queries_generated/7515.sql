
WITH sales_summary AS (
    SELECT 
        DATE(d.d_date) AS sale_date,
        s.s_store_name,
        i.i_item_id,
        i.i_item_desc,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN 
        store s ON cs.cs_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        sale_date, s_store_name, i.i_item_id, i.i_item_desc
),
top_sales AS (
    SELECT 
        sale_date,
        s_store_name,
        i_item_id,
        i_item_desc,
        total_quantity_sold,
        total_sales,
        total_discount,
        RANK() OVER (PARTITION BY sale_date ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)

SELECT 
    sale_date,
    s_store_name,
    i_item_id,
    i_item_desc,
    total_quantity_sold,
    total_sales,
    total_discount
FROM 
    top_sales
WHERE 
    sales_rank <= 5
ORDER BY 
    sale_date, total_sales DESC;
