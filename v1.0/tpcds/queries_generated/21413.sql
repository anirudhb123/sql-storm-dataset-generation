
WITH RECURSIVE Date_Range AS (
    SELECT MIN(d_date) AS start_date, MAX(d_date) AS end_date
    FROM date_dim
), Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        d.d_date AS first_purchase_date,
        cd.cd_gender,
        COALESCE(c.c_birth_year, 0) AS birth_year,
        ROW_NUMBER() OVER (PARTITION BY c.c_gender ORDER BY COALESCE(c.c_birth_year, 0)) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
), Inventory_Stats AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM inventory inv
    GROUP BY inv.inv_item_sk
), Return_Stats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM store_returns
    GROUP BY sr_item_sk
), Final_Stats AS (
    SELECT 
        ci.c_customer_id,
        ci.first_purchase_date,
        ci.cd_gender,
        NULLIF(ibs.total_quantity, 0) AS total_quantity,
        irs.total_returns,
        irs.total_return_amt,
        irs.total_return_tax
    FROM Customer_Info ci
    LEFT JOIN Inventory_Stats ibs ON ibs.inv_item_sk = ci.c_customer_sk
    LEFT JOIN Return_Stats irs ON _ = ci.c_customer_id
    WHERE ci.rn <= 10 AND (ci.birth_year IS NOT NULL OR ci.cd_gender = 'F')
)
SELECT 
    fs.c_customer_id,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(fs.total_return_amt) AS total_return_amount,
    SUM(CASE WHEN fs.total_quantity IS NULL THEN 0 ELSE fs.total_quantity END) AS total_quantity_available,
    AVG(COALESCE(wp.wp_max_ad_count, 0)) AS average_ads
FROM Final_Stats fs
JOIN web_page wp ON wp.wp_customer_sk = fs.c_customer_id AND wp.wp_creation_date_sk BETWEEN (SELECT UNIX_TIMESTAMP() FROM Date_Range)
LEFT JOIN web_sales ws ON fs.c_customer_id = ws.ws_bill_customer_sk
GROUP BY fs.c_customer_id
HAVING SUM(COALESCE(total_return_amt, 0)) > 0 OR COUNT(DISTINCT ws.ws_order_number) > 1
ORDER BY total_return_amount DESC, order_count ASC
LIMIT 50 OFFSET COALESCE(NULLIF(RANDOM(), 0), 1);
