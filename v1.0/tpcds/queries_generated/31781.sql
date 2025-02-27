
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
top_customers AS (
    SELECT 
        s.customer_id,
        COALESCE(d.cd_gender, 'U') AS gender,
        s.total_sales,
        s.order_count,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        sales_summary s
    JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE 
        s.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    a.ca_state,
    t.d_date AS sales_date,
    t.t_hour,
    COALESCE(wp.wp_url, 'No Web Page') AS web_page,
    SUM(ws_ext_sales_price) AS total_sales_by_hour,
    ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY t.t_hour) AS sales_hour_rank
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE 
    EXISTS (SELECT 1 FROM top_customers tc WHERE tc.customer_id = c.c_customer_id)
GROUP BY 
    c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, t.d_date, t.t_hour, wp.wp_url
ORDER BY 
    sales_date DESC, total_sales_by_hour DESC;
