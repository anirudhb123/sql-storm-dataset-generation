
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_net_sales,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 3
    GROUP BY 
        w.warehouse_id
)

SELECT 
    r.w_warehouse_id,
    r.total_quantity_sold,
    r.total_net_sales,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    RankedSales AS r
JOIN 
    web_sales AS ws ON r.w_warehouse_id = ws.ws_web_site_sk
JOIN 
    customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    r.rank = 1
ORDER BY 
    r.total_net_sales DESC
LIMIT 10;
