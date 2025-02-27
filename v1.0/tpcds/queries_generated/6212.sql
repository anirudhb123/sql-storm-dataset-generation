
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_quarter_seq AS sales_quarter,
        c.c_gender AS customer_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        d.d_year, d.d_quarter_seq, c.c_gender
),
customer_demographics AS (
    SELECT 
        cd.marital_status,
        cd.education_status,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.marital_status, cd.education_status
)
SELECT 
    ss.sales_year,
    ss.sales_quarter,
    ss.customer_gender,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers,
    cd.marital_status,
    cd.education_status,
    cd.num_customers,
    cd.avg_purchase_estimate
FROM 
    sales_summary ss
JOIN 
    customer_demographics cd ON ss.unique_customers = cd.num_customers
ORDER BY 
    ss.sales_year, ss.sales_quarter, ss.customer_gender;
