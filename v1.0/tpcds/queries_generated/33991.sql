
WITH RECURSIVE Sales_CTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price, ws_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231

    UNION ALL

    SELECT cs_sold_date_sk, cs_item_sk, cs_quantity, cs_sales_price, cs_net_paid
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 20220101 AND 20221231

    UNION ALL

    SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_sales_price, ss_net_paid
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 20220101 AND 20221231
),
Ranked_Sales AS (
    SELECT 
        item.i_item_id,
        SUM(s.ws_quantity) AS total_quantity_sold,
        SUM(s.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY item.i_item_id ORDER BY SUM(s.ws_net_paid) DESC) AS sales_rank
    FROM Sales_CTE s
    JOIN item item ON s.ws_item_sk = item.i_item_sk
    GROUP BY item.i_item_id
)

SELECT 
    ra.i_item_id,
    ra.total_quantity_sold,
    ra.total_net_paid,
    coalesce(r.r_reason_desc, 'No Reason') AS return_reason,
    CASE 
        WHEN ra.total_net_paid IS NULL THEN 'No Sales'
        ELSE CONCAT('Total Sales: ', ra.total_net_paid)
    END AS sales_message,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_item_sk = ra.i_item_id) AS total_web_returns
FROM Ranked_Sales ra
LEFT JOIN reason r ON ra.sales_rank = r.r_reason_sk
WHERE ra.total_quantity_sold > 0
ORDER BY ra.total_net_paid DESC;
