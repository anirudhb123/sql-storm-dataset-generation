
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_sales
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
StoreInventory AS (
    SELECT 
        i.i_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
),
MostPopularItems AS (
    SELECT 
        ws.ws_item_sk, 
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        order_count DESC
    LIMIT 10
),
ReturnsAnalysis AS (
    SELECT 
        wr.wr_item_sk, 
        SUM(wr.wr_return_quantity) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
TopSellingItem AS (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk IN (SELECT hs.c_customer_sk FROM HighSpenders hs)
    GROUP BY ws.ws_item_sk
    ORDER BY SUM(ws.ws_net_profit) DESC
    LIMIT 1
),
MostPurchasedItem AS (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk IN (SELECT hs.c_customer_sk FROM HighSpenders hs)
    GROUP BY ws.ws_item_sk
    ORDER BY SUM(ws.ws_quantity) DESC
    LIMIT 1
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.total_sales,
    si.total_quantity,
    mi.order_count AS most_popular_item_orders,
    COALESCE(ra.total_returns, 0) AS total_returns
FROM 
    HighSpenders hs
LEFT JOIN 
    StoreInventory si ON si.i_item_sk = (SELECT item_sk FROM TopSellingItem)
LEFT JOIN 
    MostPopularItems mi ON mi.ws_item_sk = (SELECT item_sk FROM MostPurchasedItem)
LEFT JOIN 
    ReturnsAnalysis ra ON ra.wr_item_sk = si.i_item_sk
WHERE 
    hs.total_sales IS NOT NULL
ORDER BY 
    hs.total_sales DESC;
