
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
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesDemographics AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
SalesRank AS (
    SELECT 
        s.*, 
        DENSE_RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SalesDemographics s
)
SELECT 
    wr.w_web_page_id,
    sr.total_sales,
    sr.sales_rank,
    CASE 
        WHEN sr.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status,
    COALESCE(sr.cd_credit_rating, 'Unknown') AS credit_rating
FROM 
    SalesRank sr
JOIN 
    web_page wr ON sr.c_customer_sk = wr.wp_customer_sk
WHERE 
    wr.wp_creation_date_sk = (SELECT MAX(wp_creation_date_sk) FROM web_page)
    AND sr.sales_rank <= 10
ORDER BY 
    sr.sales_rank;
