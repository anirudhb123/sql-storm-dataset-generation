
WITH RECURSIVE InventoryCTE AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand IS NOT NULL
    UNION ALL
    SELECT inv.inv_date_sk, inv.inv_item_sk, inv.inv_warehouse_sk, inv.inv_quantity_on_hand
    FROM inventory inv
    INNER JOIN InventoryCTE cte ON inv.inv_item_sk = cte.inv_item_sk
    WHERE inv.inv_date_sk > cte.inv_date_sk
), MonthlySales AS (
    SELECT
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_month_seq
), CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    md.d_month_seq,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(md.total_quantity) AS total_quantity,
    SUM(md.total_net_profit) AS total_net_profit,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count
FROM MonthlySales md
JOIN CustomerDetails cd ON md.d_month_seq = EXTRACT(MONTH FROM CURRENT_DATE)
GROUP BY md.d_month_seq, cd.cd_gender, cd.cd_marital_status
HAVING SUM(md.total_net_profit) > (SELECT AVG(total_net_profit)
                                     FROM MonthlySales
                                     WHERE d_month_seq = md.d_month_seq)
ORDER BY md.d_month_seq, cd.cd_gender;
