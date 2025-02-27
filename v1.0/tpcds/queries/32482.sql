
WITH RECURSIVE sales_trend AS (
    SELECT 
        ws_sold_date_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY ws_sold_date_sk) AS row_num
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    HAVING 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT 
        dd.d_date_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY dd.d_date_sk) AS row_num
    FROM 
        sales_trend st
    JOIN 
        date_dim dd ON st.ws_sold_date_sk + 1 = dd.d_date_sk
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_date_sk
)
SELECT 
    ca.ca_state,
    SUM(st.total_sales) AS total_sales_by_state,
    COUNT(DISTINCT customer.c_customer_id) AS unique_customers
FROM 
    sales_trend st
JOIN 
    store_sales ss ON st.ws_sold_date_sk = ss.ss_sold_date_sk
JOIN 
    customer ON ss.ss_customer_sk = customer.c_customer_sk
JOIN 
    customer_address ca ON customer.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_state
HAVING 
    SUM(st.total_sales) > 10000
ORDER BY 
    total_sales_by_state DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
