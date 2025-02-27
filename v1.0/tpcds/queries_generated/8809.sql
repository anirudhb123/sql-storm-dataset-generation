
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        DATE(d.d_date) AS sale_date,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
    GROUP BY 
        ws.web_site_sk, sale_date
),
SalesRank AS (
    SELECT 
        web_site_sk,
        sale_date,
        total_sales,
        total_orders,
        RANK() OVER (PARTITION BY web_site_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RankedSales
)
SELECT 
    wr.web_site_sk,
    wr.total_sales,
    wr.total_orders,
    wr.sales_rank
FROM 
    SalesRank wr
WHERE 
    wr.sales_rank <= 5
ORDER BY 
    wr.web_site_sk, wr.sales_rank;
