
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
), 
total_sales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_price,
        SUM(rs.ws_quantity) AS total_quantity
    FROM 
        ranked_sales rs
    WHERE 
        rs.price_rank <= 5
    GROUP BY 
        rs.ws_order_number
),
avg_sales AS (
    SELECT 
        AVG(total_price) AS average_price,
        AVG(total_quantity) AS average_quantity
    FROM 
        total_sales
)
SELECT 
    ca.ca_city,
    c.cd_gender,
    d.d_year,
    d.d_month_seq,
    AVG(ts.average_price) AS avg_order_price,
    COUNT(ts.ws_order_number) AS total_orders
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    total_sales ts ON ws.ws_order_number = ts.ws_order_number
GROUP BY 
    ca.ca_city, c.cd_gender, d.d_year, d.d_month_seq
HAVING 
    avg_order_price > (SELECT average_price FROM avg_sales)
ORDER BY 
    d.d_year, d.d_month_seq, ca.ca_city;
