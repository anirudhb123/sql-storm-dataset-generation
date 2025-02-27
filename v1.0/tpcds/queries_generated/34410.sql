
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws_shipping.w_ship_date_sk,
        ws_shipping.ws_item_sk,
        SUM(ws_shipping.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_shipping.w_ship_date_sk ORDER BY SUM(ws_shipping.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws_shipping
    WHERE 
        ws_shipping.ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2021) 
                                        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
    GROUP BY 
        ws_shipping.w_ship_date_sk, ws_shipping.ws_item_sk
),
TopSales AS (
    SELECT 
        w_ship_date_sk, 
        ws_item_sk, 
        total_sales
    FROM 
        SalesHierarchy 
    WHERE 
        sales_rank <= 5
),
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        sm.sm_type,
        COALESCE(tr.total_returns, 0) AS total_returns,
        th.total_sales
    FROM 
        ship_mode sm
    LEFT JOIN (
        SELECT 
            cr_ship_mode_sk,
            SUM(cr_return_quantity) AS total_returns
        FROM 
            catalog_returns
        GROUP BY 
            cr_ship_mode_sk
    ) tr ON sm.sm_ship_mode_sk = tr.cr_ship_mode_sk
    JOIN (
        SELECT 
            ws.ws_ship_mode_sk,
            SUM(ws.ws_sales_price) AS total_sales
        FROM 
            web_sales ws
        GROUP BY 
            ws.ws_ship_mode_sk
    ) th ON sm.sm_ship_mode_sk = th.ws_ship_mode_sk
)
SELECT 
    tc.total_sales,
    sm.sm_type,
    sm.total_returns,
    sm.total_sales AS mode_sales,
    ROUND((tc.total_sales - COALESCE(sm.total_returns, 0)), 2) AS net_sales
FROM 
    TopSales tc
JOIN 
    ShippingModes sm ON tc.ws_item_sk = sm.sm_ship_mode_sk 
ORDER BY 
    net_sales DESC
LIMIT 10;
