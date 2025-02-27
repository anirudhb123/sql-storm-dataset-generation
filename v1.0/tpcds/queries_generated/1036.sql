
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
)
SELECT 
    sr.c_customer_sk,
    sr.c_first_name,
    sr.c_last_name,
    sr.total_sales,
    sr.order_count,
    sr.last_purchase_date,
    CASE 
        WHEN sr.last_purchase_date IS NOT NULL AND sr.last_purchase_date < (SELECT MAX(d.d_date) FROM date_dim d WHERE d.d_current_day='Y') - INTERVAL '30 days' 
        THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status,
    (SELECT COUNT(*) FROM store_sales ss WHERE sr.c_customer_sk = ss.ss_customer_sk) AS total_store_purchases,
    (SELECT AVG(ws.ws_net_profit) FROM web_sales ws WHERE ws.ws_bill_customer_sk = sr.c_customer_sk) AS avg_web_profit
FROM SalesRanked sr
LEFT OUTER JOIN customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = sr.c_customer_sk)
WHERE cd.cd_gender = 'F' AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'M')
ORDER BY sr.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
