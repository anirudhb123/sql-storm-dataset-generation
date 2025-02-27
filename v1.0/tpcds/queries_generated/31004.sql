
WITH RECURSIVE Sales_History AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sales_price > 0
),
Inventory_Status AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
Customer_Demographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CASE
            WHEN cd_purchase_estimate BETWEEN 0 AND 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1001 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_segment
    FROM customer_demographics
),
Sales_Summary AS (
    SELECT
        sh.ws_item_sk,
        SUM(sh.ws_ext_sales_price) AS total_sales,
        SUM(sh.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT sh.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(sh.ws_ext_sales_price) DESC) AS ranked_sales
    FROM Sales_History sh
    GROUP BY sh.ws_item_sk
)
SELECT
    i.inv_item_sk,
    ss.total_sales,
    ss.total_discount,
    cs.purchase_segment,
    ISNULL(i.total_quantity_on_hand, 0) AS available_stock,
    CASE
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales > 5000 THEN 'High Sales'
        ELSE 'Regular Sales'
    END AS sales_status
FROM Inventory_Status i
FULL OUTER JOIN Sales_Summary ss ON i.inv_item_sk = ss.ws_item_sk
LEFT JOIN Customer_Demographics cs ON cs.cd_demo_sk = (SELECT TOP 1 c_current_cdemo_sk FROM customer WHERE c_customer_sk = ss.ws_item_sk ORDER BY c_customer_sk)
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_item_sk = i.inv_item_sk
    AND ss2.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
)
ORDER BY i.inv_item_sk, ss.total_sales DESC;
