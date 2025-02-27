
WITH RECURSIVE top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
customer_demographics_with_income AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        top_customers tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_income_band_sk,
    SUM(sd.total_sales) AS top_sales,
    COUNT(DISTINCT sd.ws_item_sk) AS distinct_items_purchased
FROM 
    top_customers c
JOIN 
    customer_demographics_with_income cd ON c.c_customer_sk = cd.cd_demo_sk
JOIN 
    sales_data sd ON c.c_customer_sk IN (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = sd.ws_item_sk)
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_income_band_sk
HAVING 
    COUNT(DISTINCT sd.ws_item_sk) > 5
ORDER BY 
    top_sales DESC
