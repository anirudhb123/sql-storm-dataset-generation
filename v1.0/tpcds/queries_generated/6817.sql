
WITH SalesData AS (
    SELECT 
        d.d_year AS sale_year,
        c.c_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_sales_price - ws.ws_wholesale_cost) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        d.d_year, c.c_gender
),
DemographicData AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    sd.sale_year,
    sd.c_gender,
    sd.total_quantity,
    sd.total_sales,
    sd.total_profit,
    dd.customer_count
FROM 
    SalesData sd
LEFT JOIN 
    DemographicData dd ON sd.c_gender = dd.cd_gender
ORDER BY 
    sd.sale_year, sd.c_gender;
