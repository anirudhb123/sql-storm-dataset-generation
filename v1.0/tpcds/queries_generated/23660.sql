
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL AND 
        ws.ws_quantity IS NOT NULL
),
TopPricedItems AS (
    SELECT 
        rs.ws_item_sk,
        MAX(rs.ws_sales_price) AS max_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_sales_price * ws.ws_quantity) > (SELECT AVG(total_spent) FROM (
            SELECT 
                SUM(ws2.ws_sales_price * ws2.ws_quantity) AS total_spent
            FROM 
                web_sales ws2
            GROUP BY 
                ws2.ws_bill_customer_sk
        ) AS avg_purchases)
),
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_amt) > (SELECT AVG(sr_return_amt) FROM store_returns WHERE sr_return_amt IS NOT NULL)
)
SELECT 
    c.c_customer_id,
    COALESCE(tp.max_price, 'Not Available') AS highest_price_item,
    COALESCE(CAST(CAST(hvr.total_return_value AS DECIMAL(10,2)) AS CHAR(20)), '0.00') AS return_value,
    cp.total_orders,
    cp.total_spent
FROM 
    CustomerPurchases cp
LEFT JOIN 
    TopPricedItems tp ON tp.ws_item_sk = (
        SELECT 
            ws_item_sk 
        FROM 
            store_sales 
        WHERE 
            ss_sales_price = tp.max_price 
        LIMIT 1
    )
LEFT JOIN 
    HighValueReturns hvr ON hvr.sr_item_sk = tp.ws_item_sk
WHERE 
    cp.total_orders > 3
ORDER BY 
    cp.total_spent DESC
LIMIT 10;
