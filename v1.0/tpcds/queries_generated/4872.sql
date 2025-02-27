
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 
              AND d.d_dow IN (1, 2, 3, 4, 5)
        )
    GROUP BY 
        ws.web_site_id
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
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
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    sd.web_site_id,
    sd.total_net_profit,
    sd.total_orders,
    COALESCE(rd.total_return_amt, 0) AS total_return_amt,
    rd.total_returns,
    COALESCE(id.total_inventory, 0) AS total_inventory,
    CASE 
        WHEN sd.total_orders > 0 THEN (sd.total_net_profit / sd.total_orders)
        ELSE 0
    END AS avg_profit_per_order
FROM 
    SalesData sd
LEFT JOIN 
    ReturnData rd ON sd.web_site_id = (
        SELECT wp.wp_web_page_id 
        FROM web_page wp 
        WHERE wp.wp_web_page_sk = (SELECT MIN(wp.web_page_sk) FROM web_page)
    )
LEFT JOIN 
    InventoryData id ON id.inv_item_sk = (
        SELECT MIN(i.i_item_sk) 
        FROM item i 
        WHERE i.i_current_price IS NOT NULL
    )
WHERE 
    sd.total_net_profit > 1000
ORDER BY 
    sd.total_net_profit DESC;
