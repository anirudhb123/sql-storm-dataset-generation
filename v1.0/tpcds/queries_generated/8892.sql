
WITH sales_summary AS (
    SELECT 
        d.d_year,
        c.c_birth_year,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL 
        AND c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        d.d_year, c.c_birth_year
),
average_sales AS (
    SELECT 
        d_year,
        AVG(total_sales) AS avg_sales,
        AVG(order_count) AS avg_orders,
        AVG(total_quantity) AS avg_quantity
    FROM 
        sales_summary
    GROUP BY 
        d_year
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(as.avg_sales) AS avg_sales_by_demographics
    FROM 
        average_sales as
    JOIN 
        customer c ON m.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    AVG(cd.avg_sales_by_demographics) AS avg_sales_by_gender_marital_status
FROM 
    customer_demographics cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    avg_sales_by_gender_marital_status DESC
LIMIT 10;
