
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_moy IN (11, 12) -- Last two months of the year
    GROUP BY 
        ws.web_site_id
), CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    rs.web_site_id,
    rs.total_sales,
    rs.order_count,
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.customer_rank
FROM 
    RankedSales rs
JOIN 
    CustomerInfo ci ON rs.total_sales > 1e5 -- Only consider high-value websites
WHERE 
    rs.sales_rank <= 5 -- Top 5 performing websites
ORDER BY 
    rs.total_sales DESC, ci.customer_rank;
