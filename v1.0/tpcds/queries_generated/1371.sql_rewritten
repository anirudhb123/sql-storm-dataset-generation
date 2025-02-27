WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM CustomerSales c
),
NullCheck AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender IS NULL THEN 'Unknown'
            ELSE cd.cd_gender 
        END AS gender,
        COALESCE(cd.cd_marital_status, 'Single') AS marital_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        tc.c_customer_sk,
        CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name,
        tc.total_profit,
        nc.gender,
        nc.marital_status
    FROM TopCustomers tc
    JOIN NullCheck nc ON tc.c_customer_sk = nc.c_customer_sk
    WHERE tc.profit_rank <= 10
)
SELECT 
    fr.full_name,
    fr.total_profit,
    fr.gender,
    fr.marital_status,
    COALESCE((
        SELECT COUNT(*) 
        FROM store s 
        WHERE s.s_number_employees > 50
        AND s.s_store_sk IN (
            SELECT ws.ws_ship_addr_sk 
            FROM web_sales ws 
            WHERE ws.ws_bill_customer_sk = fr.c_customer_sk
        )
    ), 0) AS store_count
FROM FinalReport fr
ORDER BY fr.total_profit DESC;