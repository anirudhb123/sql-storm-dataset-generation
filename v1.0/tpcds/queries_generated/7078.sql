
WITH sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_sales_price) AS average_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        DATEDIFF(CURDATE(), MIN(d.d_date)) AS days_since_first_sale
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        cs.cs_item_sk
),

top_items AS (
    SELECT 
        si.i_item_id,
        ss.total_quantity_sold,
        ss.total_sales,
        ss.average_sales_price,
        ss.total_orders,
        ss.days_since_first_sale
    FROM 
        sales_summary ss
    JOIN 
        item si ON ss.cs_item_sk = si.i_item_sk
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)

SELECT 
    ti.i_item_id,
    ti.total_quantity_sold,
    ti.total_sales,
    ti.average_sales_price,
    ti.total_orders,
    ti.days_since_first_sale,
    ca.ca_city,
    ca.ca_state
FROM 
    top_items ti
JOIN 
    customer c ON c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M')
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    ti.total_sales DESC;
