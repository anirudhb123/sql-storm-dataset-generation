
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month_seq = 12
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS customer_total_sales,
        COUNT(ws.ws_order_number) AS customer_total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_web_site_sk IN (SELECT DISTINCT w.web_site_sk FROM web_site w JOIN TopWebSites tw ON w.web_site_id = tw.web_site_id)
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(cs.customer_total_orders) AS order_count,
        AVG(cs.customer_total_sales) AS avg_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.cd_gender,
    cd.order_count,
    cd.avg_sales,
    COALESCE(pd.p_promo_name, 'No Promotion') AS promo_name
FROM 
    CustomerDemographics cd
LEFT JOIN 
    promotion pd ON cd.order_count > 10
ORDER BY 
    cd.avg_sales DESC;
