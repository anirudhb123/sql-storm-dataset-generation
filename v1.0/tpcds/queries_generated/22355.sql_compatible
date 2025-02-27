
WITH RECURSIVE Customer_Purchase_Summary AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER(PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_quantity) DESC) AS order_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_sk
),
High_Value_Customers AS (
    SELECT
        cps.c_customer_sk,
        cps.total_orders,
        cps.total_profit,
        cps.total_quantity
    FROM Customer_Purchase_Summary cps
    WHERE cps.total_profit > (
        SELECT AVG(total_profit) 
        FROM Customer_Purchase_Summary
    )
    AND cps.total_quantity > 100
),
Store_Performance AS (
    SELECT
        ss.s_store_sk,
        SUM(ss.ss_net_profit) AS store_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        (SELECT COUNT(DISTINCT ss2.ss_ticket_number)
         FROM store_sales ss2
         WHERE ss2.ss_store_sk = ss.s_store_sk
         AND ss2.ss_sold_date_sk IN (
             SELECT d.d_date_sk
             FROM date_dim d
             WHERE d.d_year = 2023
             AND d.d_day_name = 'Monday'
         )
        ) AS order_count_mondays
    FROM store_sales ss
    GROUP BY ss.s_store_sk
)
SELECT
    sc.s_store_sk,
    sc.store_profit,
    hvc.c_customer_sk,
    hvc.total_orders,
    hvc.total_profit,
    hvc.total_quantity,
    CASE
        WHEN sc.store_profit > (SELECT AVG(store_profit) FROM Store_Performance) THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_category,
    COALESCE(NULLIF(hvc.total_profit / NULLIF(sc.total_quantity_sold, 0), 0), 0) AS profit_per_item
FROM Store_Performance sc
JOIN High_Value_Customers hvc ON hvc.total_orders > (
    SELECT AVG(total_orders) FROM High_Value_Customers
)
WHERE hvc.total_quantity BETWEEN 1 AND 1000
ORDER BY sc.store_profit DESC, hvc.total_profit DESC;
