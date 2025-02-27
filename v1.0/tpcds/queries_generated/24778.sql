
WITH RecursiveDateRange AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_date = (SELECT MIN(d_date) FROM date_dim)
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year
    FROM date_dim d
    INNER JOIN RecursiveDateRange r ON d.d_date_sk = r.d_date_sk + 1
),
AggSales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        COUNT(ws.order_number) AS order_count,
        MAX(ws.sold_date_sk) AS last_purchase_date
    FROM web_sales ws
    WHERE ws.sold_date_sk IN (SELECT d_date_sk FROM RecursiveDateRange)
    GROUP BY ws.bill_customer_sk
),
CustomerPromo AS (
    SELECT 
        c.c_customer_sk,
        MAX(p.p_promo_id) AS last_promo_id,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count
    FROM customer c
    LEFT JOIN promotion p ON c.c_customer_sk = p.p_item_sk
    GROUP BY c.c_customer_sk
),
FinalReport AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        cd.cd_gender,
        ad.total_sales,
        p.last_promo_id,
        p.promo_count,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ad.total_sales DESC) AS city_rank
    FROM customer_address ca
    INNER JOIN customer_demographics cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = ca.ca_address_sk)
    INNER JOIN AggSales ad ON ad.bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = ca.ca_address_sk)
    LEFT JOIN CustomerPromo p ON p.c_customer_sk = ad.bill_customer_sk
    WHERE (ad.total_sales IS NOT NULL OR p.last_promo_id IS NOT NULL)
    AND (cd.cd_gender IS NOT NULL OR ad.order_count > 0)
)
SELECT 
    ca_address_sk,
    ca_city, 
    cd_gender, 
    total_sales, 
    last_promo_id,
    promo_count,
    CASE 
        WHEN city_rank <= 10 THEN 'Top 10'
        WHEN city_rank BETWEEN 11 AND 50 THEN 'Top 50'
        ELSE 'Other'
    END AS sales_category
FROM FinalReport
WHERE (total_sales > 1000 OR promo_count > 5)
ORDER BY ca_city, total_sales DESC;
