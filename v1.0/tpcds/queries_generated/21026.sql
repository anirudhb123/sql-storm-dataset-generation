
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        COALESCE(NULLIF(srd.spent, 0), 1) AS spent,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM web_sales ws
    LEFT JOIN LATERAL (
        SELECT SUM(ws_ext_sales_price) AS spent
        FROM web_sales
        WHERE ws_sold_date_sk = ws.ws_sold_date_sk AND ws_item_sk = ws.ws_item_sk
    ) srd ON TRUE
    WHERE ws.ws_quantity > 0
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        IIF(SUM(sd.ws_quantity) IS NULL, 0, SUM(sd.ws_quantity)) AS total_quantity,
        IIF(SUM(sd.ws_sales_price) IS NULL, 0, SUM(sd.ws_sales_price)) AS total_sales
    FROM sales_data sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
item_ranks AS (
    SELECT 
        is.item_sk,
        is.total_quantity,
        is.total_sales,
        RANK() OVER (ORDER BY is.total_sales DESC) AS sales_rank
    FROM (
        SELECT 
            i.i_item_sk AS item_sk,
            COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_quantity
        FROM inventory inv
        RIGHT JOIN item i ON inv.inv_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk
    ) AS inv_data 
    INNER JOIN item_sales is ON is.i_item_sk = inv_data.item_sk
)
SELECT 
    ir.item_sk,
    ir.total_quantity,
    ir.total_sales,
    CASE
        WHEN ir.total_sales = 0 THEN 'No sales'
        ELSE 'Sales exist'
    END AS sales_status,
    MAX(CASE WHEN ir.total_quantity IS NULL THEN 0 ELSE ir.total_quantity END) AS max_quantity,
    MIN(CASE WHEN ir.total_sales < 0 THEN 0 ELSE ir.total_sales END) AS min_sales,
    SUM(ir.total_quantity) OVER (PARTITION BY ir.sales_rank) AS cumulative_quantity,
    COUNT(*) FILTER (WHERE ir.total_sales > 100) AS high_value_sales_count
FROM item_ranks ir
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = (SELECT ca.c_current_cdemo_sk FROM customer ca WHERE ca.c_first_name LIKE 'A%')
WHERE ir.sales_rank <= 10 OR ir.total_sales > (SELECT AVG(total_sales) FROM item_sales)
GROUP BY ir.item_sk, ir.total_quantity, ir.total_sales
ORDER BY ir.sales_rank;
