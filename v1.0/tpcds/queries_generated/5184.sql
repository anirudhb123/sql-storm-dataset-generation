
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    wd.wd_url,
    SUM(ws.ws_net_paid) AS total_online_sales
FROM 
    TopCustomers tc
JOIN 
    web_page wd ON tc.c_customer_sk = wd.wp_customer_sk
JOIN 
    web_sales ws ON wd.wp_web_page_sk = ws.ws_web_page_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, wd.wd_url
ORDER BY 
    total_online_sales DESC;
