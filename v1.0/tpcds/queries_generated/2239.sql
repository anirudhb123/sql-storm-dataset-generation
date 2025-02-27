
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_profit,
        cs.gender_rank
    FROM
        CustomerStats cs
    JOIN
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE
        cs.total_profit > (SELECT AVG(total_profit) FROM CustomerStats)
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_orders, 0) AS total_orders,
    COALESCE(tc.total_profit, 0) AS total_profit,
    CASE 
        WHEN tc.gender_rank IS NOT NULL THEN 'In Top ' || tc.gender_rank
        ELSE 'Below Average'
    END AS status,
    (SELECT COUNT(*) FROM store s WHERE s.s_open_date IS NULL) AS closed_stores,
    (SELECT COUNT(*) FROM warehouse w WHERE w.w_warehouse_sq_ft > 50000) AS large_warehouses
FROM 
    TopCustomers tc
LEFT JOIN
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE
    ca.ca_state = 'NY' OR ca.ca_country = 'USA'
ORDER BY 
    tc.total_profit DESC, tc.c_last_name ASC;
