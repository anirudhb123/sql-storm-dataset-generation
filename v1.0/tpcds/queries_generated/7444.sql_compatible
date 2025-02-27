
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
TopSales AS (
    SELECT 
        web_site_id, 
        total_quantity, 
        total_sales
    FROM 
        RankedSales 
    WHERE 
        sales_rank = 1
)
SELECT 
    ts.web_site_id,
    ts.total_quantity,
    ts.total_sales,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopSales ts
JOIN 
    web_site ws ON ts.web_site_id = ws.web_site_id
JOIN 
    customer_address ca ON ws.web_site_id = ca.ca_address_id
WHERE 
    ca.ca_country = 'USA'
ORDER BY 
    ts.total_sales DESC;
