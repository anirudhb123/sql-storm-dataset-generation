
WITH RECURSIVE DateRange AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2022
    UNION ALL
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    JOIN DateRange dr ON d.d_date_sk = dr.d_date_sk + 1
),
RankedSales AS (
    SELECT
        ws.web_site_id,
        w.w_warehouse_name,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rnk
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM DateRange)
    GROUP BY ws.web_site_id, w.w_warehouse_name, ws.ws_item_sk
),
TopItems AS (
    SELECT
        r.web_site_id,
        r.w_warehouse_name,
        r.ws_item_sk,
        r.total_sales
    FROM RankedSales r
    WHERE r.rnk <= 10
),
CustomerData AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1001 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    c.c_customer_id,
    c.c_birth_country,
    c.cd_gender,
    c.cd_marital_status,
    t.ws_item_sk,
    t.total_sales,
    CASE 
        WHEN c.cd_gender IS NULL THEN 'Unknown'
        ELSE c.cd_gender
    END AS gender_status,
    COALESCE(MAX(cd.purchase_category), 'Not Available') AS purchase_category,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM TopItems t
JOIN CustomerData c ON t.ws_item_sk = c.c_customer_id
LEFT JOIN web_sales ws ON t.ws_item_sk = ws.ws_item_sk
GROUP BY c.c_customer_id, c.c_birth_country, c.cd_gender, c.cd_marital_status, t.ws_item_sk, t.total_sales
HAVING SUM(t.total_sales) > (SELECT AVG(total_sales) FROM RankedSales)
ORDER BY c.c_birth_country, total_sales DESC
LIMIT 50
OFFSET (SELECT COUNT(*) FROM CustomerData) / 2;
