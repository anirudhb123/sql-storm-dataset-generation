
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        s.s_store_name,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    GROUP BY 
        c.c_customer_id, s.s_store_name
),
TopCustomers AS (
    SELECT 
        r.c_customer_id,
        r.s_store_name,
        r.total_sales 
    FROM 
        RankedSales r 
    WHERE 
        r.sales_rank <= 5
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    tc.s_store_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    (SELECT COUNT(*) 
     FROM store_returns sr 
     WHERE sr.sr_customer_sk = c.c_customer_sk) AS return_count,
    (SELECT COUNT(*) 
     FROM catalog_returns cr 
     WHERE cr.cr_returning_customer_sk = c.c_customer_sk) AS catalog_return_count
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    TopCustomers tc ON c.c_customer_id = tc.c_customer_id
WHERE 
    cd.cd_marital_status = 'M' 
    AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
ORDER BY 
    total_sales DESC, c.c_last_name ASC;
