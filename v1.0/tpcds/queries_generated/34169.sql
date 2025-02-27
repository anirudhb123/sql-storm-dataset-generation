
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
AggregateSales AS (
    SELECT 
        total_sales,
        AVG(total_orders) OVER () AS avg_orders,
        MAX(total_sales) AS max_sales,
        MIN(total_sales) AS min_sales
    FROM 
        SalesHierarchy
),
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
    HAVING 
        SUM(ws.ws_net_paid) IS NOT NULL
),
ReturnsStatistics AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)

SELECT 
    i.i_item_desc,
    COALESCE(S.total_quantity_sold, 0) AS sold_quantity,
    COALESCE(R.return_count, 0) AS total_returns,
    COALESCE(R.total_return_amt, 0) AS total_return_amount,
    S.total_sales AS customer_sales,
    A.avg_orders,
    A.max_sales,
    A.min_sales
FROM 
    ItemInfo i
LEFT JOIN 
    ReturnsStatistics R ON i.i_item_sk = R.wr_item_sk
LEFT JOIN 
    SalesHierarchy S ON S.c_customer_sk = (SELECT MAX(c.c_customer_sk) FROM customer c)
CROSS JOIN 
    AggregateSales A
ORDER BY 
    customer_sales DESC
FETCH FIRST 100 ROWS ONLY;
