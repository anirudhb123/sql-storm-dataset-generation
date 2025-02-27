
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451550
    GROUP BY 
        c.c_customer_sk
),
gender_statistics AS (
    SELECT 
        cd.cd_gender,
        COUNT(cs.c_customer_sk) AS customer_count,
        AVG(cs.total_sales) AS avg_sales,
        SUM(cs.total_orders) AS total_orders
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_gender
),
state_sales AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_ext_sales_price) AS state_sales
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451550
    GROUP BY 
        ca.ca_state
)
SELECT 
    gs.cd_gender,
    gs.customer_count,
    gs.avg_sales,
    gs.total_orders,
    ss.state_sales
FROM 
    gender_statistics gs
LEFT JOIN 
    state_sales ss ON ss.state_sales IS NOT NULL
ORDER BY 
    gs.cd_gender;
