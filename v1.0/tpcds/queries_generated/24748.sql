
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.item_sk, 
        ws.net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS rank
    FROM web_sales ws
    WHERE ws.sold_date_sk >= (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq = 10
    )
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
ReturnStatistics AS (
    SELECT 
        sr.returned_date_sk, 
        COUNT(sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amt
    FROM store_returns sr 
    GROUP BY sr.returned_date_sk
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    COALESCE(SUM(r.net_profit), 0) AS total_profit,
    COALESCE(AVG(h.pc_return_value), 0) AS avg_return_value,
    COALESCE(hv.purchase_rank, 0) AS high_value_customer_rank,
    CASE 
        WHEN SUM(r.net_profit) IS NULL THEN 'No Sales' 
        ELSE 'Sales Exist' 
    END AS sales_status
FROM warehouse w
LEFT JOIN RankedSales r ON r.web_site_sk = w.w_warehouse_sk
LEFT JOIN (
    SELECT 
        ws.ship_mode_sk, 
        SUM(ws.net_paid) / COUNT(DISTINCT ws.order_number) AS pc_return_value
    FROM web_sales ws
    JOIN ReturnStatistics rs ON rs.returned_date_sk = ws.ship_date_sk
    GROUP BY ws.ship_mode_sk
) h ON h.ship_mode_sk = r.item_sk
LEFT JOIN HighValueCustomers hv ON hv.c_customer_id = (
    SELECT c.c_customer_id 
    FROM customer c 
    WHERE c.c_current_addr_sk IS NULL
    LIMIT 1
)
GROUP BY w.w_warehouse_id, w.w_warehouse_name, hv.purchase_rank
HAVING SUM(r.net_profit) IS NOT NULL OR COUNT(hv.c_customer_id) > 0
ORDER BY total_profit DESC, avg_return_value ASC
FETCH FIRST 10 ROWS ONLY;
