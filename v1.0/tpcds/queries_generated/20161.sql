
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
                               (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
CustomerReturns AS (
    SELECT
        wr_item_sk,
        wr_return_quantity,
        SUM(wr_return_amt) AS total_return_amt
    FROM
        web_returns
    GROUP BY
        wr_item_sk, wr_return_quantity
),
InventoryStatus AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM
        inventory
    WHERE
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY
        inv_item_sk
),
FinalResults AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_net_profit,
        cs.total_return_amt,
        is.total_quantity,
        CASE 
            WHEN rs.ws_net_profit IS NULL THEN 'No Profit'
            WHEN is.total_quantity IS NULL THEN 'Out of Stock'
            ELSE 'Good Standing'
        END AS status
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cs ON rs.ws_item_sk = cs.wr_item_sk
    LEFT JOIN 
        InventoryStatus is ON rs.ws_item_sk = is.inv_item_sk
    WHERE 
        rs.rank_profit = 1
)
SELECT
    f.ws_item_sk,
    f.ws_order_number,
    f.ws_sales_price,
    f.ws_net_profit,
    COALESCE(f.total_return_amt, 0) AS effective_return_amt,
    COALESCE(f.total_quantity, 0) AS available_quantity,
    f.status
FROM 
    FinalResults f
ORDER BY 
    f.ws_net_profit DESC,
    f.available_quantity ASC
LIMIT 50;
