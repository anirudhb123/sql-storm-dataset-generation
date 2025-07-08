
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
ReturnData AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
),
InventoryData AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        inventory inv
    WHERE
        inv.inv_date_sk = (SELECT MAX(inv_sub.inv_date_sk) FROM inventory inv_sub)
    GROUP BY
        inv.inv_item_sk
)
SELECT
    i.i_item_id,
    COALESCE(sd.ws_quantity, 0) AS total_sold,
    COALESCE(rd.total_returned, 0) AS total_returned,
    COALESCE(id.total_inventory, 0) AS total_inventory,
    CASE 
        WHEN COALESCE(id.total_inventory, 0) > 0 THEN 
            COALESCE(sd.ws_net_profit, 0) / COALESCE(id.total_inventory, 1)
        ELSE 
            0 
    END AS profit_per_inventory_unit,
    cd.cd_gender,
    cd.cd_credit_rating
FROM 
    item i
LEFT JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk AND sd.profit_rank = 1
LEFT JOIN 
    ReturnData rd ON i.i_item_sk = rd.wr_item_sk
LEFT JOIN 
    InventoryData id ON i.i_item_sk = id.inv_item_sk
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = i.i_item_sk LIMIT 1))
WHERE 
    (COALESCE(sd.ws_quantity, 0) > 0 OR COALESCE(rd.total_returned, 0) > 0)
ORDER BY 
    profit_per_inventory_unit DESC
LIMIT 100;
