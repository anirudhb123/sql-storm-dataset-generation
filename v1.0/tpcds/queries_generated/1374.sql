
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.total_returns,
        cr.total_return_value,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_return_value DESC) AS rank_within_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_return_value > 1000
),
WarehouseSales AS (
    SELECT 
        ws.w_warehouse_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.w_warehouse_sk
),
BestSellingItems AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    HAVING 
        total_quantity_sold > 1000
)
SELECT 
    c.customer_id,
    c.gender,
    c.marital_status,
    w.warehouse_id,
    w.total_sales,
    w.total_net_profit,
    i.i_item_id,
    bi.total_quantity_sold,
    bi.total_profit
FROM 
    HighValueCustomers c
LEFT JOIN 
    WarehouseSales w ON w.w_warehouse_sk IN (
        SELECT 
            inv.inv_warehouse_sk 
        FROM 
            inventory inv 
        WHERE 
            inv.inv_quantity_on_hand > 50
    )
JOIN 
    BestSellingItems bi ON bi.i_item_id IN (
        SELECT 
            i.i_item_id 
        FROM 
            item i
        WHERE 
            i.i_current_price BETWEEN 20 AND 50
    )
WHERE 
    c.rank_within_gender <= 10
ORDER BY 
    c.gender, 
    c.total_return_value DESC, 
    w.total_net_profit DESC;
