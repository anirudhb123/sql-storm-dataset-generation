
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighProfitCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM CustomerStats cs
    WHERE cs.total_profit > (SELECT AVG(total_profit) FROM CustomerStats)
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_number_employees,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_quantity_sold,
        ROUND(SUM(ss.ss_net_profit), 2) AS total_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_net_profit) DESC) AS store_rank
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_number_employees
)
SELECT 
    hpc.c_customer_sk,
    hpc.total_orders,
    hpc.total_profit,
    si.s_store_name,
    si.total_quantity_sold,
    si.total_net_profit
FROM HighProfitCustomers hpc
FULL OUTER JOIN StoreInfo si ON hpc.total_orders = si.total_quantity_sold
WHERE (hpc.total_profit IS NOT NULL OR si.total_net_profit IS NOT NULL)
  AND (si.total_quantity_sold > 10 OR hpc.total_orders IS NULL)
ORDER BY hpc.total_profit DESC NULLS LAST, si.total_net_profit DESC NULLS FIRST
FETCH FIRST 10 ROWS ONLY;
