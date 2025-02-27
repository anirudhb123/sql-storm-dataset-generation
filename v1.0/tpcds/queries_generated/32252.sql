
WITH RECURSIVE sales_trends AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year > 2018
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year, 
        SUM(cs.cs_sales_price) AS total_sales
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year > 2018
    GROUP BY 
        d.d_year
),
top_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
sales_by_store AS (
    SELECT 
        s.s_store_name, 
        SUM(ss.ss_sales_price) AS store_total
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_name
)
SELECT 
    st.d_year,
    st.total_sales AS web_catalog_sales,
    tc.c_first_name || ' ' || tc.c_last_name AS top_customer_name,
    sb.s_store_name,
    sb.store_total
FROM 
    sales_trends st
LEFT JOIN 
    top_customers tc ON st.d_year = (SELECT d.d_year FROM date_dim d WHERE d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_sales_price > 0))
LEFT JOIN 
    sales_by_store sb ON st.d_year = (SELECT d.d_year FROM date_dim d WHERE d.d_date_sk = (SELECT MAX(ss.ss_sold_date_sk) FROM store_sales ss WHERE ss.ss_sales_price > 0))
WHERE 
    st.total_sales IS NOT NULL
ORDER BY 
    st.d_year DESC, 
    sb.store_total DESC;
