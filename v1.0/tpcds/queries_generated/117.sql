
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate > 5000
),
SalesSummary AS (
    SELECT
        r.web_site_sk,
        SUM(r.ws_net_profit) AS total_profit,
        COUNT(r.ws_order_number) AS order_count
    FROM
        RankedSales r
    GROUP BY
        r.web_site_sk
)
SELECT
    w.w_warehouse_id,
    COALESCE(s.total_profit, 0) AS total_sales_profit,
    w.w_warehouse_name,
    SUM(CASE WHEN h.c_customer_sk IS NOT NULL THEN 1 ELSE 0 END) AS high_value_customer_count,
    STRING_AGG(CONCAT(h.c_first_name, ' ', h.c_last_name), ', ') AS high_value_customers
FROM
    warehouse w
LEFT JOIN SalesSummary s ON w.w_warehouse_sk = s.web_site_sk
LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN HighValueCustomers h ON ws.ws_bill_customer_sk = h.c_customer_sk
WHERE
    w.w_state = 'CA' AND (s.order_count >= 10 OR s.order_count IS NULL)
GROUP BY
    w.w_warehouse_id, w.w_warehouse_name
ORDER BY
    total_sales_profit DESC;
