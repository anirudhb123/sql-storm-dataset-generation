
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, ca.ca_city
),
demographics_summary AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.total_sales) AS total_sales_by_demo,
        AVG(ss.total_orders) AS avg_orders_by_demo,
        AVG(ss.unique_items_sold) AS avg_unique_items_sold
    FROM 
        customer_demographics cd
    JOIN 
        sales_summary ss ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    SUM(d.total_sales_by_demo) AS overall_sales,
    AVG(d.avg_orders_by_demo) AS overall_avg_orders,
    AVG(d.avg_unique_items_sold) AS overall_avg_unique_items
FROM 
    demographics_summary d
GROUP BY 
    d.cd_gender, d.cd_marital_status, d.cd_education_status
ORDER BY 
    overall_sales DESC
LIMIT 10;
