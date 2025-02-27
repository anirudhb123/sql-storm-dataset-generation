
WITH Ranked_Sales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.cd_gender,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        DENSE_RANK() OVER (PARTITION BY d.d_year, ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year IN (2021, 2022)
),
Top_Sales AS (
    SELECT 
        web_site_id,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        Ranked_Sales
    WHERE 
        rank <= 5
    GROUP BY 
        web_site_id
),
Final_Report AS (
    SELECT 
        ts.web_site_id,
        ts.total_sales,
        COUNT(rs.rank) AS top_sellers_count,
        (SELECT COUNT(*)
         FROM customer
         WHERE c_birth_year BETWEEN 1980 AND 1995) AS demographic_count
    FROM 
        Top_Sales ts
    JOIN 
        Ranked_Sales rs ON ts.web_site_id = rs.web_site_id
    GROUP BY 
        ts.web_site_id, ts.total_sales
)
SELECT 
    web_site_id,
    total_sales,
    top_sellers_count,
    demographic_count,
    ROUND(total_sales / demographic_count, 2) AS sales_per_demographic
FROM 
    Final_Report
ORDER BY 
    total_sales DESC
LIMIT 10;
