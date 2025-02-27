
WITH CustomerPurchaseStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_spent
    FROM
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
), TopSellingItems AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        total_sold,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        ItemSales i
)
SELECT 
    c.c_first_name, 
    c.c_last_name,
    cps.total_orders, 
    cps.total_quantity, 
    cps.total_spent, 
    tsi.i_product_name, 
    tsi.total_sold, 
    tsi.total_sales
FROM 
    CustomerPurchaseStats cps
JOIN 
    customer c ON cps.c_customer_sk = c.c_customer_sk
JOIN 
    TopSellingItems tsi ON cps.c_customer_sk = (
        SELECT 
            ws.ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_item_sk = tsi.i_item_sk 
        ORDER BY 
            ws.ws_quantity DESC 
        LIMIT 1
    )
WHERE 
    cps.total_orders > 5
ORDER BY 
    cps.total_spent DESC
LIMIT 10;
