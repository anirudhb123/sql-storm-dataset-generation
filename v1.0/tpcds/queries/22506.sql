
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 100.00
),
TotalReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned_items
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
MonthlyStats AS (
    SELECT 
        d_year, 
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_sales_per_order
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
),
PopularItems AS (
    SELECT 
        i_item_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    JOIN 
        item ON ws_item_sk = i_item_sk
    WHERE 
        i_current_price IS NOT NULL
    GROUP BY 
        i_item_sk
    HAVING 
        SUM(ws_quantity) > 50
)

SELECT 
    A.ws_item_sk, 
    A.ws_order_number, 
    A.ws_quantity, 
    A.ws_net_paid, 
    COALESCE(B.total_returned_items, 0) as total_returned,
    C.total_sales, 
    C.total_orders, 
    C.avg_sales_per_order, 
    D.order_count,
    D.total_quantity_sold
FROM 
    RankedSales A
LEFT JOIN 
    TotalReturns B ON A.ws_item_sk = B.cr_item_sk
JOIN 
    MonthlyStats C ON C.d_year = EXTRACT(YEAR FROM (SELECT d_date FROM date_dim WHERE d_date_sk = A.ws_order_number)) 
LEFT JOIN 
    PopularItems D ON A.ws_item_sk = D.i_item_sk
WHERE 
    (A.rn = 1 AND A.ws_net_paid IS NOT NULL)
    OR (D.total_quantity_sold > 100 AND D.order_count > 10)
ORDER BY 
    A.ws_item_sk, A.ws_order_number;
