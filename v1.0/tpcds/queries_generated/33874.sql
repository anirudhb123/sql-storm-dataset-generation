
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_brand
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, (ih.i_current_price * 0.9) AS i_current_price, i.i_brand
    FROM item i 
    JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk + 1
),
SalesStats AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451507 AND 2451590
    GROUP BY ws_item_sk
),
CustomerStatus AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COALESCE(CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Single' END, 'Unknown') AS marital_status,
        COUNT(DISTINCT COALESCE(ws.ws_order_number, cs.cs_order_number)) AS order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk, cd.cd_marital_status
),
RankedSales AS (
    SELECT
        ih.i_item_id,
        ss.total_sales,
        ss.total_orders,
        ROW_NUMBER() OVER (PARTITION BY ih.i_brand ORDER BY ss.total_sales DESC) AS rank
    FROM ItemHierarchy ih
    JOIN SalesStats ss ON ih.i_item_sk = ss.ws_item_sk
),
FinalData AS (
    SELECT 
        cs.c_customer_sk,
        cs.marital_status,
        cs.cd_gender,
        cs.hd_income_band_sk,
        rs.i_item_id,
        rs.total_sales
    FROM CustomerStatus cs
    JOIN RankedSales rs ON cs.order_count > 0
    WHERE cs.hd_income_band_sk IS NOT NULL AND rs.rank <= 10
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    fd.marital_status,
    fd.cd_gender,
    fd.hd_income_band_sk,
    SUM(fd.total_sales) AS total_sales
FROM customer c
JOIN FinalData fd ON c.c_customer_sk = fd.c_customer_sk
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, fd.marital_status, fd.cd_gender, fd.hd_income_band_sk
HAVING SUM(fd.total_sales) > 1000
ORDER BY total_sales DESC
LIMIT 50;
