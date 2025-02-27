
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_sold_date_sk, 
        SUM(ws.ws_net_paid) AS total_sales, 
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_sk, 
        ws.ws_sold_date_sk
), 
SalesByWebsite AS (
    SELECT 
        w.warehouse_name, 
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        warehouse w ON rs.web_site_sk = w.warehouse_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    sbw.warehouse_name, 
    sbw.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    SalesByWebsite sbw
JOIN 
    customer c ON c.c_current_cdemo_sk = sbw.web_site_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    sbw.warehouse_name, 
    sbw.total_sales, 
    cd.cd_gender, 
    cd.cd_marital_status
ORDER BY 
    sbw.total_sales DESC;
