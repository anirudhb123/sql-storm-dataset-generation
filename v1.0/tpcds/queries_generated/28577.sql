
WITH sales_summary AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        MIN(d.d_date) AS first_sale_date,
        MAX(d.d_date) AS last_sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_order_number
), 
address_counts AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COUNT(DISTINCT case when cd.cd_gender = 'F' then c.c_customer_sk end) AS female_count,
        COUNT(DISTINCT case when cd.cd_gender = 'M' then c.c_customer_sk end) AS male_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_city
), 
sales_per_city AS (
    SELECT 
        SUBSTRING(heavy_sales.city, 1, 10) AS city,
        heavy_sales.total_quantity,
        heavy_sales.total_sales
    FROM (
        SELECT 
            a.ca_city,
            SUM(s.total_quantity) AS total_quantity,
            SUM(s.total_sales) AS total_sales
        FROM 
            address_counts a
        JOIN 
            sales_summary s ON a.customer_count > 0 AND a.customer_count > 10
        GROUP BY 
            a.ca_city
        HAVING 
            SUM(s.total_quantity) > 1000
    ) AS heavy_sales
)
SELECT 
    city,
    total_quantity,
    total_sales,
    (SELECT COUNT(*) FROM address_counts ac WHERE ac.city = heavy_sales.city) AS related_customers
FROM 
    sales_per_city heavy_sales
ORDER BY 
    total_sales DESC;
