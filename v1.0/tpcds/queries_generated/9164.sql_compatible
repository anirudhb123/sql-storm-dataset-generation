
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
DemographicSummary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(ss.total_sales) AS avg_sales,
        AVG(ss.total_quantity) AS avg_quantity,
        COUNT(DISTINCT ss.c_customer_id) AS customer_count
    FROM 
        SalesSummary AS ss
    JOIN 
        customer_demographics AS cd ON ss.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.avg_sales,
    ds.avg_quantity,
    ds.customer_count,
    ROW_NUMBER() OVER (ORDER BY ds.avg_sales DESC) AS sales_rank
FROM 
    DemographicSummary AS ds
WHERE 
    ds.customer_count > 10
ORDER BY 
    ds.avg_sales DESC, ds.avg_quantity DESC;
