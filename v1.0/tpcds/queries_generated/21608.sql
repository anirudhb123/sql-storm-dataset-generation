
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),

SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),

DiscountedSales AS (
    SELECT 
        s.ws_item_sk,
        CASE 
            WHEN s.total_sales > 100 THEN s.total_sales * 0.9
            ELSE s.total_sales
        END AS adjusted_sales,
        CASE 
            WHEN s.max_price > 50 THEN s.max_price * 0.95
            ELSE s.max_price
        END AS adjusted_max_price
    FROM SalesData s
),

FirstTimePurchase AS (
    SELECT 
        c.c_customer_sk,
        MIN(ws.ws_sold_date_sk) AS first_purchase_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
)

SELECT 
    rc.c_first_name,
    rc.c_last_name,
    COALESCE(SUM(ds.adjusted_sales), 0) AS adjusted_total_sales,
    COALESCE(MAX(ds.adjusted_max_price), 0) AS highest_adjusted_price,
    FIRST_VALUE(ft.first_purchase_date) OVER (PARTITION BY rc.c_customer_sk ORDER BY ft.first_purchase_date) AS first_purchase_date,
    CASE 
        WHEN rc.rnk = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM RankedCustomers rc
LEFT JOIN DiscountedSales ds ON ds.ws_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = rc.c_customer_sk LIMIT 1)
LEFT JOIN FirstTimePurchase ft ON rc.c_customer_sk = ft.c_customer_sk
WHERE rc.rnk <= 5
GROUP BY rc.c_first_name, rc.c_last_name, rc.rnk
ORDER BY adjusted_total_sales DESC, rc.c_last_name ASC;
