
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        ws.web_site_id, d.d_year
),
TopWebSites AS (
    SELECT 
        web_site_id,
        d_year,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    tws.web_site_id,
    tws.d_year,
    tws.total_sales,
    (SELECT COUNT(DISTINCT ws_item_sk) 
     FROM web_sales 
     WHERE ws_bill_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_sold_date_sk = ws_sold_date_sk)) AS unique_items_sold
FROM 
    TopWebSites AS tws
ORDER BY 
    tws.d_year, tws.total_sales DESC;
