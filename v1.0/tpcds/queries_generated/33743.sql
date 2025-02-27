
WITH RECURSIVE sales_summary AS (
    SELECT 
        d.d_date AS sale_date,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    UNION ALL
    SELECT 
        ss.sale_date,
        ss.ws_order_number,
        ss.ws_sales_price,
        ss.ws_quantity,
        ss.ws_net_paid
    FROM 
        sales_summary ss
    INNER JOIN 
        web_sales ws ON ss.ws_order_number = ws.ws_order_number
    WHERE 
        ss.ws_net_paid < 5000
)
SELECT 
    s.sale_date,
    SUM(s.ws_sales_price) AS total_sales,
    SUM(s.ws_quantity) AS total_quantity,
    AVG(s.ws_net_paid) AS avg_net_paid
FROM 
    sales_summary s
LEFT JOIN 
    customer c ON s.ws_order_number = c.c_customer_id
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' AND 
    cd.cd_marital_status = 'M' AND 
    (cd.cd_purchase_estimate >= 100 OR cd.cd_credit_rating IS NULL)
GROUP BY 
    s.sale_date
HAVING 
    SUM(s.ws_sales_price) > 10000
ORDER BY 
    total_sales DESC
LIMIT 10;
