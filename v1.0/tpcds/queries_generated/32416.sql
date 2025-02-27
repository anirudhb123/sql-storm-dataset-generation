
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
ItemSales AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(s.total_sold) AS overall_sales,
        COUNT(DISTINCT s.ws_sold_date_sk) AS sales_days
    FROM 
        SalesCTE s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name
),
CustomerRanking AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY COUNT(ws.ws_order_number) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
),
ShipModeReturns AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_refunds,
        SUM(sr_return_ship_cost) AS total_shipping_cost
    FROM 
        ship_mode sm
    LEFT JOIN 
        store_returns sr ON sm.sm_ship_mode_sk = sr.sr_reason_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    ir.i_item_id,
    ir.i_product_name,
    ir.overall_sales,
    cr.c_customer_id,
    cr.total_orders,
    cr.order_rank,
    s.sm_ship_mode_id,
    sr.total_returns,
    sr.total_refunds,
    sr.total_shipping_cost
FROM 
    ItemSales ir
JOIN 
    CustomerRanking cr ON ir.overall_sales > 0
JOIN 
    ShipModeReturns sr ON sr.total_returns > 0
LEFT JOIN 
    ship_mode s ON cr.order_rank <= 10
WHERE 
    ir.overall_sales > 1000
ORDER BY 
    ir.overall_sales DESC, cr.order_rank;
