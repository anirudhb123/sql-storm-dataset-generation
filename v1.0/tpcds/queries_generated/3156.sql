
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL 
        AND ws.ws_sales_price > 0
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_sk,
        web_site_id
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_customer_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN 20240101 AND 20241231
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.total_customer_spent,
        c.order_count,
        RANK() OVER (ORDER BY c.total_customer_spent DESC) AS customer_rank
    FROM 
        CustomerSales c
)
SELECT 
    t.web_site_id,
    t.total_sales,
    tc.c_customer_id,
    tc.order_count,
    COALESCE(DATE_PART('year', d.d_date), 'No Data') AS sales_year
FROM 
    TopWebsites t
FULL OUTER JOIN 
    TopCustomers tc ON t.web_site_sk = tc.order_count
LEFT JOIN 
    date_dim d ON d.d_date_sk = t.web_site_sk
WHERE 
    (tc.total_customer_spent IS NOT NULL OR t.total_sales IS NOT NULL)
ORDER BY 
    t.total_sales DESC, tc.total_customer_spent DESC;
