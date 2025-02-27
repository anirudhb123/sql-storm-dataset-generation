
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss.s_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.s_sold_date_sk, ss.ss_item_sk
    HAVING 
        SUM(ss.ss_sales_price) > 10000
    UNION ALL
    SELECT 
        w.ws_sold_date_sk,
        w.ws_item_sk,
        SUM(w.ws_sales_price) AS total_sales
    FROM 
        web_sales w
    WHERE 
        w.ws_sold_date_sk IN (SELECT s_sold_date_sk FROM store_sales)
    GROUP BY 
        w.ws_sold_date_sk, w.ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate BETWEEN 5000 AND 20000
)
SELECT 
    cs.c_customer_sk,
    cs.total_store_sales,
    cs.total_web_sales,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    (cs.total_store_sales + cs.total_web_sales) AS total_sales,
    RANK() OVER (PARTITION BY d.cd_gender ORDER BY (cs.total_store_sales + cs.total_web_sales) DESC) AS sales_rank
FROM 
    CustomerSales cs
JOIN 
    Demographics d ON cs.c_customer_sk = d.cd_demo_sk
WHERE 
    cs.total_store_sales IS NOT NULL OR cs.total_web_sales IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 100;
