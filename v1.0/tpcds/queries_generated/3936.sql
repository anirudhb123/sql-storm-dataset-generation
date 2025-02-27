
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
TopSales AS (
    SELECT 
        sd.web_site_id,
        sd.total_sales,
        sd.total_orders,
        sd.average_order_value
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 5
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_dep_count) AS average_dependents
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ts.web_site_id, 
    ts.total_sales, 
    ts.total_orders, 
    ts.average_order_value, 
    cs.cd_gender, 
    cs.customer_count, 
    cs.total_purchase_estimate,
    cs.average_dependents,
    CASE 
        WHEN cs.total_purchase_estimate IS NULL THEN 'No Data'
        ELSE 'Data Available'
    END AS data_availability
FROM 
    TopSales ts
FULL OUTER JOIN 
    CustomerStats cs ON 1=1
ORDER BY 
    ts.total_sales DESC NULLS LAST, cs.customer_count DESC;
