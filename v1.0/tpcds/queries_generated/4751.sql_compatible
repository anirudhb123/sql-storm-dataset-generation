
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.web_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk, 
        COALESCE(cd.cd_gender, 'U') AS gender, 
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        AVG(CASE WHEN ss.ss_sales_price > 100 THEN ss.ss_sales_price ELSE NULL END) AS avg_high_ticket_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.gender,
        cs.total_store_sales,
        cs.total_web_sales,
        RANK() OVER (ORDER BY cs.total_store_sales + cs.total_web_sales DESC) AS customer_rank
    FROM 
        CustomerStats cs
)
SELECT 
    tc.c_customer_sk, 
    tc.gender, 
    tc.total_store_sales, 
    tc.total_web_sales,
    CASE 
        WHEN tc.total_store_sales = 0 THEN 'No Store Sales'
        ELSE 'Store Sales Present'
    END AS store_sales_status,
    CASE 
        WHEN tc.total_web_sales > 1000 THEN 'High Web Sales'
        ELSE 'Regular Web Sales'
    END AS web_sales_status,
    rs.total_sales AS web_site_total_sales
FROM 
    TopCustomers tc
LEFT JOIN 
    RankedSales rs ON tc.c_customer_sk = rs.web_site_sk
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.customer_rank;
