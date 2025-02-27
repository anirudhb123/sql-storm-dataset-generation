
WITH RecursiveCTE AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY')
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.net_paid) AS total_sales,
        COUNT(DISTINCT ss.ticket_number) AS sale_count,
        MAX(ss.sold_date_sk) AS last_purchase_date
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_holiday = 'Y')
    GROUP BY c.c_customer_id
),
TrendAnalysis AS (
    SELECT 
        ws.bill_customer_sk, 
        SUM(ws.net_paid) AS total_web_sales,
        COUNT(ws.order_number) AS web_order_count,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
),
AggregateData AS (
    SELECT 
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.ext_sales_price) AS total_catalog_sales,
        COUNT(cs.order_number) AS catalog_order_count,
        (SELECT COUNT(*) FROM catalog_page cp WHERE cp.cp_catalog_page_sk = cs.catalog_page_sk) AS page_count
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
)
SELECT 
    r.ca_city,
    r.ca_state,
    ss.total_sales,
    ss.sale_count,
    ta.total_web_sales,
    ta.web_order_count,
    ag.total_catalog_sales,
    ag.catalog_order_count,
    COALESCE(r.rn, 0) AS address_rank,
    CASE 
        WHEN ss.last_purchase_date IS NOT NULL THEN 'Active'
        ELSE 'Inactive' 
    END AS customer_status
FROM RecursiveCTE r
LEFT JOIN SalesSummary ss ON r.ca_address_sk = ss.c_customer_id
LEFT JOIN TrendAnalysis ta ON ss.c_customer_id = ta.bill_customer_sk
LEFT JOIN AggregateData ag ON ss.c_customer_id = ag.customer_sk
WHERE r.rn = (SELECT MAX(rn) FROM RecursiveCTE WHERE ca_city = r.ca_city)
ORDER BY r.ca_city, r.ca_state, ss.total_sales DESC;
