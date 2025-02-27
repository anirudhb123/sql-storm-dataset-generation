
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS revenue_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
), 
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        wr.wr_item_sk
),
WarehouseInventory AS (
    SELECT 
        i.i_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory i
    JOIN 
        warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE 
        w.w_country = 'USA'
    GROUP BY 
        i.i_item_sk
)
SELECT 
    sd.ws_item_sk,
    COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sd.total_revenue, 0) AS total_revenue,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(wi.total_inventory, 0) AS total_inventory,
    CASE 
        WHEN COALESCE(sd.total_revenue, 0) > 0 
        THEN (COALESCE(cr.total_return_amount, 0) / COALESCE(sd.total_revenue, 0)) * 100 
        ELSE NULL 
    END AS return_percentage,
    CASE 
        WHEN sd.revenue_rank IS NOT NULL AND sd.revenue_rank <= 10 
        THEN 'Top 10 Item'
        ELSE 'Other Item' 
    END AS item_category
FROM 
    SalesData sd
LEFT JOIN 
    CustomerReturns cr ON sd.ws_item_sk = cr.wr_item_sk
LEFT JOIN 
    WarehouseInventory wi ON sd.ws_item_sk = wi.i_item_sk
ORDER BY 
    sd.total_revenue DESC NULLS LAST;
