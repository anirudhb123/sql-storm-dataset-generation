
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_ship_date_sk) AS last_ship_date
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(CASE WHEN ws.ws_sales_price < 50 THEN 1 END), 0) AS low_income_count,
        COALESCE(SUM(CASE WHEN ws.ws_sales_price BETWEEN 50 AND 100 THEN 1 END), 0) AS middle_income_count,
        COALESCE(SUM(CASE WHEN ws.ws_sales_price > 100 THEN 1 END), 0) AS high_income_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
RankedDemographics AS (
    SELECT 
        cd.*,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerDemographics cd
    JOIN 
        SalesData sd ON cd.cd_demo_sk = sd.web_site_id
)
SELECT 
    rd.cd_gender,
    rd.cd_marital_status,
    rd.low_income_count,
    rd.middle_income_count,
    rd.high_income_count,
    sd.total_sales,
    sd.order_count,
    d.d_date AS report_date
FROM 
    RankedDemographics rd
JOIN 
    SalesData sd ON rd.cd_demo_sk = sd.web_site_id
CROSS JOIN 
    (SELECT DISTINCT d_date FROM date_dim WHERE d_year = 2023) d
WHERE 
    rd.sales_rank <= 5
ORDER BY 
    rd.cd_gender, sd.order_count DESC;
