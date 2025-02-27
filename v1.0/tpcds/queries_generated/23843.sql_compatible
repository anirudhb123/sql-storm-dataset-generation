
WITH RankedSales AS (
    SELECT 
        ws.item_sk,
        ws.order_number,
        ws.sales_price,
        ws.ext_sales_price,
        ws.ext_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY ws.order_number DESC) AS rn
    FROM web_sales ws
    WHERE ws.sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq = 9 AND d_dow IN (1, 2, 3)
    )
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(CASE WHEN cd.gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.marital_status = 'S' THEN 1 ELSE 0 END) AS single_count,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd.dep_count) AS unique_dependents
    FROM customer c
    JOIN customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
ExcessReturns AS (
    SELECT 
        sr.store_sk,
        SUM(sr.return_quantity) AS total_returns
    FROM store_returns sr
    GROUP BY sr.store_sk 
    HAVING SUM(sr.return_quantity) > 100
),
TotalSales AS (
    SELECT 
        cs.item_sk,
        SUM(cs.ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN item i ON cs.item_sk = i.i_item_sk
    WHERE i.i_brand = 'BrandA' 
    GROUP BY cs.item_sk
)
SELECT 
    ca.city, 
    ca.state,
    COALESCE(rs.sales_price, 0) AS last_sales_price,
    cs.avg_purchase_estimate,
    ets.total_sales,
    CASE 
        WHEN cs.male_count > 0 THEN 'Male Dominated'
        ELSE 'Female Dominated'
    END AS gender_dominance,
    COUNT(DISTINCT CASE WHEN sr.store_sk IS NOT NULL THEN sr.store_sk END) AS return_count
FROM RankedSales rs
FULL OUTER JOIN CustomerStats cs ON rs.item_sk = cs.c_customer_sk
INNER JOIN inventory i ON rs.item_sk = i.inv_item_sk
LEFT JOIN ExcessReturns sr ON i.inv_warehouse_sk = sr.store_sk
JOIN customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
LEFT JOIN TotalSales ets ON rs.item_sk = ets.item_sk
WHERE ca.state IS NOT NULL
AND (ca.city LIKE '%City%' OR ca.county LIKE '%County%')
GROUP BY ca.city, ca.state, cs.avg_purchase_estimate, ets.total_sales, rs.sales_price, cs.male_count
HAVING SUM(COALESCE(rs.sales_price, 0)) > 5000
ORDER BY ca.city ASC, last_sales_price DESC
