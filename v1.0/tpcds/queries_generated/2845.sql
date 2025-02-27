
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status
), HighSpenders AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rn
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    COALESCE(r.r_reason_desc, 'No Reason') AS return_reason
FROM 
    HighSpenders cs
LEFT JOIN 
    store_returns sr ON cs.c_customer_id = sr.sr_customer_sk
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE 
    cs.rn <= 10
ORDER BY 
    cs.total_sales DESC;
