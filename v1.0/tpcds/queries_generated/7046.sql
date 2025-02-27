
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws.ws_order_number
),
TopSales AS (
    SELECT 
        web_site_id,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
)
SELECT 
    ts.web_site_id,
    cs.cd_gender,
    cs.order_count,
    cs.total_items_purchased,
    ts.total_sales
FROM 
    TopSales ts
JOIN 
    CustomerStats cs ON ts.web_site_id = (SELECT ws_id FROM web_site WHERE web_site_sk = ws.web_site_sk)
ORDER BY 
    ts.total_sales DESC, cs.order_count DESC;
