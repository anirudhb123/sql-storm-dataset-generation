
WITH RankedSales AS (
    SELECT 
        ws.customer_sk,
        ws_item_sk,
        ws_quantity,
        RANK() OVER (PARTITION BY ws.customer_sk ORDER BY ws_sold_date_sk DESC) as sale_rank,
        SUM(ws_sales_price) OVER (PARTITION BY ws.customer_sk) as total_spent
    FROM web_sales ws
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) as dep_count,
        COALESCE(SUM(RS.ws_quantity), 0) as total_quantity,
        MAX(RS.total_spent) as max_spent,
        MIN(RS.ws_item_sk) as first_purchased_item
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN RankedSales RS ON c.c_customer_sk = RS.customer_sk
    GROUP BY c.c_customer_sk, c_first_name, c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count
),
HighValueCustomers AS (
    SELECT *
    FROM CustomerSummary
    WHERE max_spent > (SELECT AVG(max_spent) FROM CustomerSummary)
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.dep_count,
    CASE 
        WHEN hvc.total_quantity > 10 THEN 'High'
        WHEN hvc.total_quantity BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END as purchase_category,
    CONCAT(hvc.c_first_name, ' ', hvc.c_last_name) AS full_name
FROM HighValueCustomers hvc
LEFT JOIN customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = hvc.c_customer_sk)
WHERE ca.ca_state IS NOT NULL
ORDER BY hvc.max_spent DESC;
