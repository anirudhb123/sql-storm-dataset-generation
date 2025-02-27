
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
TopSellingSites AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_ext_sales_price) AS total_spent
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ss.ss_ext_sales_price) > 1000
)

SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.total_spent,
    tss.web_site_id,
    tss.total_sales,
    tss.total_orders
FROM 
    CustomerInfo AS ci
JOIN 
    TopSellingSites AS tss ON ci.total_spent > tss.total_sales / tss.total_orders
ORDER BY 
    ci.total_spent DESC, tss.total_sales DESC;
