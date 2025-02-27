
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
SalesStatistics AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        AVG(ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450582 AND 2450588
    GROUP BY ss_store_sk
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_marital_status,
    rc.cd_gender,
    ss.total_net_profit,
    ss.avg_sales_price,
    ss.transaction_count,
    CASE 
        WHEN ss.total_net_profit IS NULL THEN 'No Profit'
        ELSE 'Profit Recorded'
    END AS profit_status,
    COALESCE(ss.total_net_profit / NULLIF(ss.transaction_count, 0), 0) AS avg_profit_per_transaction,
    CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS full_name,
    RANK() OVER (ORDER BY COALESCE(ss.total_net_profit, 0) DESC) AS customer_profit_rank
FROM RankedCustomers rc
LEFT JOIN SalesStatistics ss ON rc.c_customer_id = ss.ss_store_sk
WHERE rc.rank = 1 
  AND (rc.cd_gender = 'F' OR rc.cd_gender IS NULL)
ORDER BY ss.total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
