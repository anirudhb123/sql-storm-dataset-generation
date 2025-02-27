
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
), 
DemographicStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cs.total_sales) AS avg_sales,
        AVG(cs.order_count) AS avg_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
), 
DateSales AS (
    SELECT 
        dd.d_year,
        SUM(ws.ws_ext_sales_price) AS yearly_sales
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_year
)
SELECT 
    ds.d_year,
    ds.yearly_sales,
    ds.yearly_sales / NULLIF((SELECT SUM(yearly_sales) FROM DateSales), 0) * 100 AS sales_percentage,
    ds.yearly_sales - COALESCE((SELECT ds.yearly_sales FROM DateSales ds2 WHERE ds2.d_year = ds.d_year - 1), 0) AS year_over_year_growth,
    ds.yearly_sales * 0.1 AS projected_future_sales,
    ds2.avg_sales AS avg_sales_per_demographic,
    ds2.avg_orders AS avg_orders_per_demographic
FROM 
    DateSales ds
LEFT JOIN 
    DemographicStats ds2 ON ds2.avg_sales > 0
ORDER BY 
    ds.d_year DESC
LIMIT 10;
