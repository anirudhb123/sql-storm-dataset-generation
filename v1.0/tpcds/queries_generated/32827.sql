
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk AS sales_date,
        ws_item_sk,
        ws_store_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk, ws_store_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_spent,
        COUNT(DISTINCT ws_order_number) AS total_web_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
top_selling_items AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(ws_ext_sales_price) AS total_sales_value,
        RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM item 
    JOIN web_sales ON item.i_item_sk = web_sales.ws_item_sk
    GROUP BY item.i_item_id, item.i_product_name
)
SELECT 
    cust.c_first_name AS FirstName,
    cust.c_last_name AS LastName,
    cust.cd_gender AS Gender,
    item.i_product_name AS TopSellingItem,
    item.total_sales_value AS TopSalesValue,
    cust.total_store_spent AS StoreSpent,
    cust.total_web_orders AS WebOrders,
    CASE 
        WHEN cust.total_store_spent IS NULL THEN 'No Store Purchases'
        ELSE 'Has Store Purchases'
    END AS PurchaseStatus
FROM customer_data cust 
JOIN top_selling_items item ON item.sales_rank = 1
WHERE cust.hd_income_band_sk IS NOT NULL
ORDER BY cust.total_web_orders DESC, cust.total_store_spent NULLS LAST;
