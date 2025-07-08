
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, 0 AS level
    FROM item
    WHERE i_item_sk IN (SELECT cs_item_sk FROM catalog_sales WHERE cs_sold_date_sk = (SELECT MAX(cs_sold_date_sk) FROM catalog_sales))

    UNION ALL

    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk
    WHERE i.i_item_sk IS NOT NULL
),
SalesStatistics AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_sales_price * cs.cs_quantity) AS total_sales,
        COUNT(cs.cs_order_number) AS number_of_orders,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_sales_price * cs.cs_quantity) DESC) AS rank
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs.cs_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.cd_gender,
        c.cd_marital_status,
        c.total_purchases,
        c.total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM CustomerData c
    WHERE c.total_purchases > 10
)
SELECT 
    ih.i_item_id,
    ih.i_item_desc,
    ss.total_sales,
    ss.number_of_orders,
    tc.total_spent AS customer_spending,
    tc.cd_gender,
    CASE 
        WHEN tc.cd_marital_status = 'M' THEN 'Married'
        WHEN tc.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status
FROM ItemHierarchy ih
JOIN SalesStatistics ss ON ih.i_item_sk = ss.cs_item_sk
LEFT JOIN TopCustomers tc ON tc.c_customer_sk = (SELECT ss.ss_customer_sk FROM store_sales ss WHERE ss.ss_item_sk = ih.i_item_sk LIMIT 1)
WHERE ss.rank <= 10
ORDER BY ss.total_sales DESC, tc.total_spent DESC
LIMIT 50;
