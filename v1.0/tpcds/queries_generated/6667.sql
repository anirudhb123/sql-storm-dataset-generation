
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
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
        total_sales,
        total_quantity
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.cd_gender,
    ts.web_site_id,
    ts.total_sales,
    ts.total_quantity
FROM 
    TopSales ts
JOIN 
    web_site ws ON ts.web_site_id = ws.web_site_id
JOIN 
    CustomerInfo ci ON ci.c_customer_id = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_order_number = ts.ws_order_number LIMIT 1)
ORDER BY 
    ts.total_sales DESC;
