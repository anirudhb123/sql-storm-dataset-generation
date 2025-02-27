
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        s.s_store_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store AS s ON ws.ws_store_sk = s.s_store_sk
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_week_seq, s.s_store_name
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_sales) AS sales_per_demographic
    FROM 
        sales_summary AS ss
    JOIN 
        customer AS c ON ss.unique_customers = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.sales_per_demographic,
    CASE 
        WHEN cd.sales_per_demographic > 10000 THEN 'High Spender'
        WHEN cd.sales_per_demographic BETWEEN 5000 AND 10000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS customer_category
FROM 
    customer_demographics AS cd
ORDER BY 
    cd.sales_per_demographic DESC;
