
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk AS sold_date_sk,
        EXTRACT(YEAR FROM d.d_date) AS sold_year,
        d.d_month AS sold_month,
        d.d_dow AS sold_day_of_week,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        sold_date_sk, sold_year, sold_month, sold_day_of_week
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
active_customers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(distinct sd.sold_date_sk) AS purchase_days,
        SUM(sd.total_sales) AS total_spent
    FROM 
        sales_data sd
    JOIN 
        customer_data c ON sd.sold_date_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        purchase_days > 0
)
SELECT 
    a.cd_gender,
    a.cd_marital_status,
    COUNT(DISTINCT a.c_customer_sk) AS num_customers,
    AVG(b.total_spent) AS avg_spent,
    SUM(b.total_spent) AS total_spent
FROM 
    customer_data a
JOIN 
    active_customers b ON a.c_customer_sk = b.c_customer_sk
GROUP BY 
    a.cd_gender, a.cd_marital_status
ORDER BY 
    num_customers DESC, total_spent DESC
LIMIT 10;
