
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_net_paid) > 1000
),
ReturnsSummary AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk
)
SELECT 
    w.w_warehouse_id,
    COALESCE(HighValueCustomers.total_spent, 0) AS total_spent_by_customers,
    COALESCE(SUM(RankedSales.ws_net_profit), 0) AS total_net_profit,
    COALESCE(SUM(ReturnsSummary.total_returns), 0) AS total_returns,
    COUNT(DISTINCT HIGH.DemoSk) AS unique_high_value_cust_count
FROM warehouse w
LEFT JOIN RankedSales ON w.w_warehouse_sk = RankedSales.web_site_sk
LEFT JOIN HighValueCustomers ON HighValueCustomers.c_customer_sk = 
    (SELECT COALESCE(MAX(c.c_customer_sk), 0) FROM customer c WHERE c.c_current_addr_sk IS NOT NULL)
LEFT JOIN ReturnsSummary ON ReturnsSummary.sr_item_sk = 
    (SELECT MAX(sr.sr_item_sk) FROM store_returns sr WHERE sr.sr_return_amt IS NOT NULL)
WHERE w.w_warehouse_sq_ft > 2000
GROUP BY w.w_warehouse_id
HAVING COALESCE(SUM(RankedSales.ws_net_profit), 0) > 5000
ORDER BY total_net_profit DESC;
