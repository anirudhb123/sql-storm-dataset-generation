
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_quantity DESC) AS rank
    FROM web_sales AS ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim AS d 
        WHERE d.d_year = 2023 AND d.d_dow BETWEEN 1 AND 5
    )
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_quantity DESC) AS rank
    FROM catalog_sales AS cs
    WHERE cs.cs_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim AS d 
        WHERE d.d_year = 2023 AND d.d_dow BETWEEN 1 AND 5
    )
),
total_sales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_sales_price) AS total_sales_price,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM sales_data AS sd
    WHERE sd.rank <= 3
    GROUP BY sd.ws_order_number
),
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        COALESCE(ri.r_reason_desc, 'No Reason') AS return_reason
    FROM item AS i
    LEFT JOIN reason AS ri ON i.i_item_sk = ri.r_reason_sk
)
SELECT 
    ts.ws_order_number,
    id.i_item_id,
    id.i_product_name,
    ts.total_quantity,
    ts.total_sales_price,
    ts.total_net_profit,
    id.i_current_price,
    CASE 
        WHEN ts.total_net_profit IS NULL THEN 'Profit Not Available'
        WHEN ts.total_net_profit <= 0 THEN 'No Profit'
        ELSE 'Profitable'
    END AS profit_status,
    SUBSTRING(id.return_reason, 1, 20) AS short_return_reason
FROM total_sales AS ts
JOIN item_details AS id ON ts.ws_order_number = id.i_item_id
WHERE ts.total_quantity > 10 
  AND (ts.total_sales_price / NULLIF(ts.total_quantity, 0) > 50.00 
       OR (id.i_current_price - COALESCE(NULLIF(ts.total_net_profit, 0), NULL)) < 10)
ORDER BY ts.total_net_profit DESC, ts.ws_order_number;
