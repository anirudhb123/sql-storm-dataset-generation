
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        c.total_sales,
        c.order_count,
        RANK() OVER (PARTITION BY c.customer_sk ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
),
FrequentBuyers AS (
    SELECT 
        customer_sk,
        first_name,
        last_name,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    f.customer_sk,
    f.first_name,
    f.last_name,
    f.total_sales,
    f.order_count,
    (SELECT COUNT(DISTINCT ws.web_site_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = f.customer_sk) AS unique_websites,
    (SELECT AVG(ws.ws_net_profit) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = f.customer_sk) AS avg_net_profit
FROM 
    FrequentBuyers f
LEFT JOIN 
    customer_demographics cd ON f.customer_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') 
    OR (cd.cd_gender = 'M' AND cd.cd_marital_status IS NULL)
ORDER BY 
    f.total_sales DESC;
