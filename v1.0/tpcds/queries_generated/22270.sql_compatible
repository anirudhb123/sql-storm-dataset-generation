
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' 
      AND cd.cd_marital_status = 'S' 
      AND ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2023)
    GROUP BY ws.item_sk
),
FilteredSales AS (
    SELECT * 
    FROM SalesCTE
    WHERE rank <= 10
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        fs.total_quantity,
        fs.total_profit,
        CASE 
            WHEN fs.total_profit IS NULL THEN 'Unknown' 
            ELSE i.i_category 
        END AS item_category
    FROM FilteredSales fs
    JOIN item i ON fs.item_sk = i.i_item_sk
)
SELECT 
    COALESCE(id.item_category, 'General') AS category,
    COUNT(*) AS number_of_items,
    MAX(id.total_quantity) AS max_quantity_sold,
    AVG(id.total_profit) AS average_profit
FROM ItemDetails id
LEFT JOIN store s ON s.s_store_sk IN (
    SELECT sr.s_store_sk 
    FROM store_returns sr 
    WHERE sr.s_return_quantity >= 1
)
GROUP BY id.item_category
ORDER BY max_quantity_sold DESC;
