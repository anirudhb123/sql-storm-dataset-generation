
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000

    UNION ALL

    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_hdemo_sk = ch.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 500
),
SalesSummary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
FilteredSales AS (
    SELECT c.*, ss.total_sales, ss.order_count
    FROM CustomerHierarchy c
    LEFT JOIN SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT c.*, 
           RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.total_sales DESC) AS sales_rank,
           DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS overall_rank
    FROM FilteredSales c
    WHERE c.total_sales IS NOT NULL
)
SELECT c.c_customer_id, c.c_first_name, c.c_last_name,
       c.cd_gender, c.cd_marital_status, c.total_sales, 
       c.order_count, c.sales_rank, c.overall_rank
FROM RankedCustomers c
WHERE c.total_sales > 1000 AND c.sales_rank <= 5
ORDER BY c.cd_gender, c.total_sales DESC
