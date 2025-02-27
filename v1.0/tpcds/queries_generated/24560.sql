
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        ws_item_sk,
        total_quantity
    FROM SalesCTE
    WHERE sales_rank <= 10
),
HighNetProfit AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    GROUP BY ss_item_sk
    HAVING SUM(ss_net_profit) > (
        SELECT AVG(ss_net_profit) 
        FROM store_sales 
        GROUP BY ss_item_sk
    )
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        COALESCE(i.i_product_name, 'Unknown Product') AS product_name,
        COALESCE(SUM(ws.net_profit), 0) AS web_net_profit,
        COALESCE(SUM(ss.net_profit), 0) AS store_net_profit
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    d.d_date AS sale_date,
    c.c_customer_id,
    o.item_details,
    COALESCE(o.web_net_profit, 0) + COALESCE(o.store_net_profit, 0) AS total_net_profit
FROM date_dim d
JOIN (
    SELECT 
        CASE 
            WHEN r.r_reason_desc IS NOT NULL THEN r.r_reason_desc 
            ELSE 'No Reason Provided' 
        END AS item_details,
        i.i_item_sk,
        i.i_product_name,
        hs.total_net_profit,
        ws.total_quantity
    FROM item i
    JOIN (
        SELECT 
            ws_item_sk,
            SUM(ws_net_profit) AS total_net_profit
        FROM web_sales
        GROUP BY ws_item_sk
    ) hs ON i.i_item_sk = hs.ws_item_sk
    LEFT JOIN reason r ON r.r_reason_sk IS NULL 
    WHERE hs.total_net_profit IS NOT NULL
) o ON o.item_details = 'Some Specific Criteria'
LEFT JOIN customer c ON c.c_current_cdemo_sk IN (
    SELECT cd_demo_sk
    FROM customer_demographics
    WHERE cd_marital_status = 'M' 
      AND cd_gender = 'F'
)
WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY d.d_date, total_net_profit DESC
LIMIT 100
OFFSET 10;
