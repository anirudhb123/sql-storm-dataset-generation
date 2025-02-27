
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ext_sales_price) AS total_sales, 
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.web_site_sk = w.web_site_sk
    LEFT JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
        AND ws.sold_date_sk BETWEEN 2451545 AND 2451819
    GROUP BY 
        ws.web_site_id
), 
top_sales AS (
    SELECT 
        web_site_id, 
        total_sales
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    w.web_name,
    w.web_country,
    ts.total_sales
FROM 
    top_sales ts
JOIN 
    web_site w ON ts.web_site_id = w.web_site_id
ORDER BY 
    ts.total_sales DESC;
