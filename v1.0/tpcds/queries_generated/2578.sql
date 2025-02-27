
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
customer_locations AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address AS ca
    LEFT JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state
),
total_returns AS (
    SELECT
        wr_returned_date_sk,
        COUNT(*) AS total_web_returns,
        SUM(wr_return_amt) AS total_return_value
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk
)

SELECT 
    cl.ca_city,
    cl.ca_state,
    SUM(COALESCE(rs.total_sales, 0)) AS total_web_sales,
    SUM(COALESCE(tr.total_web_returns, 0)) AS total_web_returns,
    SUM(COALESCE(cl.customer_count, 0)) AS total_customers,
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    AVG(rs.total_sales) AS avg_order_value
FROM 
    customer_locations AS cl
LEFT JOIN 
    ranked_sales AS rs ON cl.ca_state = rs.web_site_sk
LEFT JOIN 
    total_returns AS tr ON rs.ws_order_number = tr.wr_order_number
GROUP BY 
    cl.ca_city, cl.ca_state
HAVING 
    SUM(COALESCE(rs.total_sales, 0)) > 10000
ORDER BY 
    total_web_sales DESC;
