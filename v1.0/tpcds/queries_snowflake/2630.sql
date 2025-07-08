
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459790 AND 2459797
),
FilteredReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_spent,
        MAX(ws.ws_sales_price) AS max_spent,
        MIN(ws.ws_sales_price) AS min_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        cd.cd_marital_status
),
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk, 
        rs.ws_order_number, 
        rs.ws_quantity, 
        rs.ws_sales_price,
        COALESCE(fr.total_returned, 0) AS total_returned,
        COALESCE(fr.total_return_amt, 0) AS total_return_amt
    FROM 
        RankedSales rs
    LEFT JOIN 
        FilteredReturns fr ON rs.ws_item_sk = fr.wr_item_sk
)
SELECT 
    ss.ws_item_sk,
    SUM(ss.ws_sales_price) AS total_sales,
    AVG(ss.ws_sales_price) AS avg_price,
    SUM(ss.total_returned) AS total_returns,
    MAX(cs.total_orders) AS most_orders_by_customer,
    LISTAGG(CONCAT(cs.c_customer_sk, ': ', cs.total_spent), ', ') AS customer_spending_stats
FROM 
    SalesWithReturns ss
JOIN 
    CustomerStats cs ON ss.ws_order_number IN (
        SELECT ws_order_number 
        FROM web_sales 
        WHERE ws_item_sk = ss.ws_item_sk
    )
GROUP BY 
    ss.ws_item_sk
HAVING 
    SUM(ss.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC;
