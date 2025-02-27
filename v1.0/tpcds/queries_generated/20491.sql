
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS item_rank,
        ws.ws_ship_date_sk,
        wd.d_year,
        ws_c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim wd ON ws.ws_ship_date_sk = wd.d_date_sk
    WHERE 
        wd.d_year IN (SELECT d_year FROM date_dim WHERE d_year BETWEEN 2019 AND 2021)
        AND cd.cd_gender = 'F'
),
HighValueReturns AS (
    SELECT 
        sr.returned_date,
        sr.return_quantity,
        sr.return_amt, 
        r.r_reason_desc,
        (CASE 
            WHEN sr.return_amt > 100 THEN 'High Value Return'
            ELSE 'Standard Return'
        END) AS return_type
    FROM 
        store_returns sr
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    ORDER BY 
        sr.returned_date DESC
),
ShippingModes AS (
    SELECT 
        sm.sm_type,
        COUNT(sm.sm_ship_mode_sk) AS mode_count
    FROM 
        ship_mode sm
    WHERE 
        sm.sm_carrier IS NOT NULL
    GROUP BY 
        sm.sm_type
)
SELECT 
    r.order_year AS year,
    COUNT(DISTINCT r.ws_order_number) AS total_orders,
    SUM(r.total_quantity) AS total_quantity,
    AVG(CASE WHEN h.return_type = 'High Value Return' THEN h.return_quantity ELSE NULL END) AS avg_high_value_returns,
    sm.mode_type AS shipping_mode,
    MAX(COALESCE(r.ws_ext_sales_price, 0)) AS max_sales_price
FROM 
    RankedSales r
LEFT JOIN 
    HighValueReturns h ON r.ws_order_number = h.returned_date
JOIN 
    ShippingModes sm ON sm.mode_count > (
        SELECT AVG(mode_count) FROM ShippingModes
    )
GROUP BY 
    year, sm.mode_type
HAVING 
    total_orders >= 10
ORDER BY 
    total_orders DESC, year ASC;
