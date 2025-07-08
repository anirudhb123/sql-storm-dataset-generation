
WITH RECURSIVE IncomeBands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk IN (SELECT DISTINCT hd_income_band_sk FROM household_demographics WHERE hd_buy_potential = 'High')
    
    UNION ALL
    
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    INNER JOIN IncomeBands ib_parent ON ib.ib_lower_bound BETWEEN ib_parent.ib_lower_bound AND ib_parent.ib_upper_bound
),
CustomerOrderStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_orders,
        SUM(s.ss_sales_price) AS total_sales,
        AVG(COALESCE(s.ss_net_profit, 0)) AS avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ss_sales_price) DESC) AS order_rank
    FROM customer c
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(i.ib_income_band_sk, -1) AS income_band_sk,
        cs.total_orders,
        cs.total_sales,
        cs.avg_net_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN IncomeBands i ON cd.cd_purchase_estimate BETWEEN i.ib_lower_bound AND i.ib_upper_bound
    JOIN CustomerOrderStats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE cs.order_rank <= 10
)
SELECT *
FROM (
    SELECT 
        tc.*,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        CASE 
            WHEN total_orders IS NULL THEN 'No Orders'
            ELSE 'Orders Exist'
        END AS order_status,
        CASE 
            WHEN total_sales IS NULL THEN 'Unknown Sales'
            ELSE 'Sales Known'
        END AS sales_status,
        CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name
    FROM TopCustomers tc
) AS customer_full_info
WHERE sales_rank <= 5 OR order_status = 'No Orders'
ORDER BY total_sales DESC NULLS LAST;
