
WITH sales_summary AS (
    SELECT 
        ws_b.bill_customer_sk,
        ws_b.web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales ws_b
    JOIN 
        date_dim d ON ws_b.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws_b.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2023
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ws_b.bill_customer_sk, ws_b.web_site_sk
),
demographic_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_sales,
        cs.order_count,
        cs.avg_profit
    FROM 
        customer_demographics cd
    JOIN 
        sales_summary cs ON cd.cd_demo_sk = cs.bill_customer_sk
)
SELECT 
    di.cd_gender,
    di.cd_marital_status,
    COUNT(di.cd_demo_sk) AS customer_count,
    SUM(di.total_sales) AS total_sales,
    AVG(di.avg_profit) AS average_profit
FROM 
    demographic_info di
GROUP BY 
    di.cd_gender, di.cd_marital_status
ORDER BY 
    total_sales DESC, customer_count DESC
LIMIT 10;
