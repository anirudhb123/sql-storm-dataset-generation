
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.bill_addr_sk,
        ws.ws_order_number,
        ws_ext_sales_price,
        ws_ext_tax,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.ws_order_number DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1995
),
CustomerStats AS (
    SELECT 
        bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_profit) AS avg_profit_per_order
    FROM RankedSales
    WHERE sales_rank <= 5
    GROUP BY bill_customer_sk
),
HighProfitCustomers AS (
    SELECT 
        cs.bill_customer_sk, 
        cs.total_orders, 
        cs.total_profit,
        cs.avg_profit_per_order,
        cd.cd_gender,
        cd.cd_marital_status
    FROM CustomerStats cs
    JOIN customer_demographics cd ON cs.bill_customer_sk = cd.cd_demo_sk
    WHERE cs.total_profit > 1000
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    hpc.total_orders,
    hpc.total_profit,
    hpc.avg_profit_per_order,
    cd.cd_gender,
    cd.cd_marital_status,
    a.ca_city,
    a.ca_state
FROM HighProfitCustomers hpc
JOIN customer c ON hpc.bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
ORDER BY hpc.total_profit DESC
LIMIT 10;
