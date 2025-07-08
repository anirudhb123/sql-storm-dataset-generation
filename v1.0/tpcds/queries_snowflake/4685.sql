
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        SUM(CASE WHEN wd.d_holiday = 'Y' THEN ws.ws_net_paid ELSE 0 END) AS holiday_sales,
        COUNT(CASE WHEN wd.d_weekend = 'Y' THEN 1 END) AS weekend_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    GROUP BY 
        c.c_customer_id
),
DemographicSales AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cs.c_customer_id) AS demographic_count,
        AVG(cs.total_web_sales) AS avg_web_sales,
        SUM(cs.total_orders) AS total_orders,
        SUM(cs.holiday_sales) AS total_holiday_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = cs.c_customer_id)
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count,
    d.avg_web_sales,
    d.total_orders,
    d.total_holiday_sales,
    ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY d.total_holiday_sales DESC) AS rank_by_holiday_sales
FROM 
    DemographicSales d
WHERE 
    d.total_orders > 100
ORDER BY 
    d.total_holiday_sales DESC
LIMIT 10;
