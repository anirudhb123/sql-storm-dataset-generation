
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        w.w_warehouse_id, i.i_item_id
),
TopSellingItems AS (
    SELECT 
        warehouse_id,
        i_item_id,
        total_quantity,
        total_profit
    FROM 
        RankedSales
    WHERE 
        rank <= 3
),

DemographicsSales AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ts.total_quantity) AS total_item_quantity,
        SUM(ts.total_profit) AS total_item_profit
    FROM 
        TopSellingItems ts
    JOIN 
        customer c ON c.c_customer_sk = ts.w_warehouse_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)

SELECT 
    cd_gender,
    cd_marital_status,
    total_item_quantity,
    total_item_profit,
    RANK() OVER (ORDER BY total_item_profit DESC) AS profit_rank
FROM 
    DemographicsSales
WHERE 
    total_item_profit > 0
ORDER BY 
    total_item_profit DESC;
