
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cc.cc_name,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN call_center cc ON c.c_customer_id LIKE '%' || cc.cc_call_center_id || '%'
    WHERE c.c_birth_year IS NOT NULL AND cd.cd_marital_status IN ('M', 'S')
    GROUP BY c.c_customer_id, cc.cc_name, cd.cd_gender
), 
HighProfitCustomers AS (
    SELECT 
        rc.*,
        CASE 
            WHEN total_profit IS NULL THEN 'No Profit'
            WHEN total_profit > 1000 THEN 'High Value'
            ELSE 'Standard Value'
        END AS customer_value
    FROM RankedCustomers rc
    WHERE avg_purchase_estimate IS NOT NULL AND avg_purchase_estimate > 500
    HAVING COUNT(DISTINCT ss_ticket_number) > 5
)
SELECT 
    hpc.c_customer_id,
    hpc.cc_name,
    hpc.cd_gender,
    hpc.gender_rank,
    hpc.store_sales_count,
    hpc.total_profit,
    hpc.customer_value,
    COALESCE((
        SELECT COUNT(*)
        FROM web_returns wr
        WHERE wr.wr_returning_customer_sk = hpc.c_customer_sk
        AND wr.wr_return_quantity > 0
    ), 0) AS total_web_returns,
    CONCAT('Estimated profit margin: ', ROUND((hpc.total_profit / NULLIF(SUM(cs.cs_net_profit), 0)) * 100, 2), '%') AS profit_margin_percentage
FROM HighProfitCustomers hpc
LEFT JOIN catalog_sales cs ON hpc.c_customer_id = cs.cs_bill_customer_sk
GROUP BY hpc.c_customer_id, hpc.cc_name, hpc.cd_gender, hpc.gender_rank, hpc.store_sales_count, hpc.total_profit, hpc.customer_value
ORDER BY hpc.total_profit DESC, hpc.store_sales_count ASC
FETCH FIRST 10 ROWS ONLY;
