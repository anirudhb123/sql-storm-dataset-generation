
WITH RECURSIVE month_sales AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.year, 
        SUM(ws.ws_net_paid) + ms.total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        month_sales ms ON ms.d_year = d.d_year - 1
    GROUP BY 
        d.d_year
),
sales_by_gender AS (
    SELECT 
        cd.cd_gender, 
        SUM(ws.ws_net_paid) AS gender_sales,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rnk
    FROM 
        customer_demographics cd
    JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        cd.cd_gender
),
top_sales AS (
    SELECT 
        s.cd_gender, 
        s.gender_sales
    FROM 
        sales_by_gender s
    WHERE 
        s.rnk <= 5
)
SELECT 
    ma.d_year, 
    ma.total_sales, 
    COALESCE(ts.gender_sales, 0) AS male_sales, 
    COALESCE(ts.gender_sales, 0) AS female_sales
FROM 
    month_sales ma
LEFT JOIN 
    top_sales ts ON ts.cd_gender = CASE 
        WHEN ma.d_year % 2 = 0 THEN 'M' 
        ELSE 'F' 
    END
WHERE 
    ma.total_sales > 100000
ORDER BY 
    ma.d_year DESC;
