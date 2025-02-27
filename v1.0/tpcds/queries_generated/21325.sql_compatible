
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND c.c_current_addr_sk IN (
            SELECT ca.ca_address_sk
            FROM customer_address ca
            WHERE ca.ca_state = 'CA'
              AND ca.ca_zip LIKE '9%')
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk, ws.ws_sales_price
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price) AS total_sales,
        COUNT(rs.ws_order_number) AS order_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
    GROUP BY 
        rs.ws_item_sk
),
LowStockItems AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS on_hand
    FROM 
        inventory inv
    WHERE 
        inv.inv_quantity_on_hand < 10
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ti.ws_item_sk,
    ti.total_sales,
    ti.order_count,
    COALESCE(ls.on_hand, 0) AS stock_on_hand,
    CASE 
        WHEN ls.on_hand IS NOT NULL THEN 'Low Stock'
        ELSE 'Sufficient Stock'
    END AS stock_status
FROM 
    TopItems ti
LEFT JOIN 
    LowStockItems ls ON ti.ws_item_sk = ls.inv_item_sk
WHERE 
    (ti.total_sales > 1000 OR ti.order_count > 50)
ORDER BY 
    ti.total_sales DESC,
    stock_on_hand ASC
FETCH FIRST 50 ROWS ONLY;
