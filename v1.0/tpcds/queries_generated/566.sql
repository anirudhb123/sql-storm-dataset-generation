
WITH AddressCount AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_sales, 
        sd.order_count
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
),
ShipModes AS (
    SELECT 
        sm.sm_ship_mode_sk,
        sm.sm_type,
        COUNT(ws.web_site_sk) AS order_count
    FROM 
        ship_mode sm
    LEFT JOIN 
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_sk, sm.sm_type
)
SELECT 
    ca.ca_state,
    ac.address_count,
    ti.total_sales,
    si.sm_type,
    sm.order_count AS ship_mode_order_count
FROM 
    AddressCount ac
JOIN 
    customer_address ca ON ca.ca_state = ac.ca_state
LEFT JOIN 
    TopItems ti ON ti.ws_item_sk = ca.ca_address_sk
LEFT JOIN 
    ShipModes sm ON sm.order_count = (
        SELECT COUNT(*) 
        FROM web_sales 
        WHERE ws_item_sk = ti.ws_item_sk
    )
WHERE 
    ac.address_count > 5
    AND (ti.total_sales IS NULL OR ti.total_sales > 1000)
ORDER BY 
    ac.ca_state, 
    ti.total_sales DESC NULLS LAST;
