
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk
),
Timings AS (
    SELECT 
        d.d_date,
        EXTRACT(DOW FROM d.d_date) AS day_of_week,
        CASE 
            WHEN frequency <= 10 THEN 'Low'
            WHEN frequency <= 50 THEN 'Medium'
            ELSE 'High'
        END AS sales_frequency,
        SUM(CASE WHEN sd.total_net_profit > 1000 THEN 1 ELSE 0 END) as high_profit_days
    FROM 
        date_dim d
    JOIN (
        SELECT 
            ws.ws_sold_date_sk,
            COUNT(*) AS frequency
        FROM 
            web_sales ws
        GROUP BY 
            ws.ws_sold_date_sk
    ) sales ON d.d_date_sk = sales.ws_sold_date_sk
    LEFT JOIN SalesData sd ON sd.ws_sold_date_sk = sales.ws_sold_date_sk
    GROUP BY 
        d.d_date, sales.frequency
)
SELECT 
    cd.full_name,
    cd.c_email_address,
    cd.ca_city,
    cd.ca_state,
    t.d_date AS sales_date,
    t.day_of_week,
    t.sales_frequency,
    s.total_net_profit,
    s.total_orders,
    s.unique_customers
FROM 
    CustomerDetails cd
JOIN 
    SalesData s ON cd.c_customer_sk = s.ws_bill_customer_sk
JOIN 
    Timings t ON s.ws_sold_date_sk = (SELECT sd.ws_sold_date_sk FROM SalesData sd WHERE cd.c_customer_sk = sd.ws_bill_customer_sk LIMIT 1)
ORDER BY 
    sales_date DESC, total_net_profit DESC
LIMIT 50;
