
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_name,
        c.c_first_name,
        c.c_last_name,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        w.w_warehouse_name, c.c_first_name, c.c_last_name, ws.ws_order_number
),
TopSales AS (
    SELECT 
        warehouse_name,
        c_first_name,
        c_last_name,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
NullReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk IS NULL
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    ts.warehouse_name,
    ts.c_first_name,
    ts.c_last_name,
    ts.total_sales,
    COALESCE(nr.total_return_amt, 0) AS total_return_amt,
    (ts.total_sales - COALESCE(nr.total_return_amt, 0)) AS net_sales,
    CASE 
        WHEN (ts.total_sales - COALESCE(nr.total_return_amt, 0)) < 0 THEN 'Negative'
        ELSE 'Positive'
    END AS sales_status
FROM 
    TopSales ts
LEFT JOIN 
    NullReturns nr ON ts.c_first_name || ' ' || ts.c_last_name = (SELECT 
                                                                      c.c_first_name || ' ' || c.c_last_name 
                                                                      FROM customer c 
                                                                      WHERE c.c_customer_sk = nr.wr_returning_customer_sk LIMIT 1)
ORDER BY 
    ts.warehouse_name, net_sales DESC;
