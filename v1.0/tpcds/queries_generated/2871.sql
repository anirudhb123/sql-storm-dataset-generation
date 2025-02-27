
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER(PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        cs.cs_item_sk, cs.cs_order_number
),
TopProfitableItems AS (
    SELECT
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.profit_rank <= 10
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        COALESCE(i.i_current_price, 0) AS current_price,
        COALESCE(i.i_wholesale_cost, 0) AS wholesale_cost
    FROM 
        item i
)
SELECT 
    tpi.cs_item_sk,
    id.i_item_id,
    id.i_product_name,
    id.i_brand,
    tpi.total_quantity,
    tpi.total_net_profit,
    id.current_price,
    id.wholesale_cost,
    (tpi.total_net_profit / NULLIF(tpi.total_quantity, 0)) AS avg_net_profit_per_unit,
    (id.current_price - id.wholesale_cost) AS profit_margin
FROM 
    TopProfitableItems tpi
LEFT JOIN 
    ItemDetails id ON tpi.cs_item_sk = id.i_item_sk
WHERE 
    (profit_margin > 0) OR (profit_margin IS NULL)
ORDER BY 
    tpi.total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
