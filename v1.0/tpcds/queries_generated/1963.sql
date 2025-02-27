
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.total_orders
    FROM 
        RankedSales cs
    WHERE 
        cs.sales_rank <= 10
),
ReturnedItems AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        ti.i_item_id,
        tc.total_sales,
        COALESCE(ri.total_returns, 0) AS total_returns,
        (tc.total_sales - COALESCE(ri.total_returns * ti.i_current_price, 0)) AS net_sales
    FROM 
        item ti
    LEFT JOIN 
        TopCustomers tc ON ti.i_item_sk = tc.total_orders
    LEFT JOIN 
        ReturnedItems ri ON ti.i_item_sk = ri.wr_item_sk
)
SELECT 
    s.s_store_name,
    SUM(sar.net_sales) AS net_profit,
    AVG(CASE WHEN sar.net_sales IS NOT NULL THEN sar.net_sales ELSE 0 END) AS avg_net_sales,
    COUNT(sar.i_item_id) AS items_sold
FROM 
    SalesAndReturns sar
JOIN 
    store s ON s.s_store_sk = (SELECT ws.ws_warehouse_sk FROM web_sales ws WHERE ws.ws_item_sk = sar.i_item_sk LIMIT 1)
GROUP BY 
    s.s_store_name
ORDER BY 
    net_profit DESC;
