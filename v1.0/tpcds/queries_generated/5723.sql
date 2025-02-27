
WITH SalesData AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_sold_date_sk, 
        SUM(ws.ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023 
        AND cd.cd_gender = 'M'
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
SalesRanked AS (
    SELECT 
        sd.web_site_sk, 
        sd.ws_sold_date_sk, 
        sd.total_sales, 
        sd.order_count, 
        sd.unique_customers,
        RANK() OVER (PARTITION BY sd.web_site_sk ORDER BY sd.total_sales DESC) AS rank_within_site
    FROM 
        SalesData sd
)
SELECT 
    wr.WebSite_ID,
    wr.total_sales,
    wr.order_count,
    wr.unique_customers,
    wr.rank_within_site
FROM 
    SalesRanked wr
JOIN 
    web_site ws ON wr.web_site_sk = ws.web_site_sk
WHERE 
    wr.rank_within_site <= 10
ORDER BY 
    wr.total_sales DESC;
