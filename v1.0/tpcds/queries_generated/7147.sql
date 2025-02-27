
WITH sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        ws.bill_cdemo_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON ws.bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND ws.ws_sold_date_sk BETWEEN 2459000 AND 2459080
    GROUP BY 
        ws.bill_customer_sk,
        ws.bill_cdemo_sk
),
demographics_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    s.bill_customer_sk,
    s.total_sales,
    s.order_count,
    s.avg_quantity,
    d.address_count,
    d.avg_income_band
FROM 
    sales_summary s
JOIN 
    demographics_summary d ON s.bill_cdemo_sk = d.cd_demo_sk
WHERE 
    s.total_sales > 1000
ORDER BY 
    s.total_sales DESC
LIMIT 50;
