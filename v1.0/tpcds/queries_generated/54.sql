
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
CustomerReturns AS (
    SELECT 
        wr_ret.wr_returning_customer_sk,
        SUM(wr_ret.wr_return_quantity) AS total_return_quantity,
        SUM(wr_ret.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr_ret
    GROUP BY 
        wr_ret.wr_returning_customer_sk
),
TopSales AS (
    SELECT 
        sd.web_site_sk,
        SUM(sd.ws_net_paid) AS total_net_paid,
        COUNT(sd.ws_item_sk) AS total_items_sold
    FROM 
        SalesData sd
    WHERE 
        sd.rank <= 10
    GROUP BY 
        sd.web_site_sk
)
SELECT 
    ws.w_warehouse_id,
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cr.total_return_quantity, 0) AS returned_quantity,
    COALESCE(cr.total_return_amt, 0) AS returned_amount,
    ts.total_net_paid,
    ts.total_items_sold
FROM 
    warehouse ws
JOIN 
    store s ON ws.w_warehouse_sk = s.s_store_sk
JOIN 
    customer cs ON s.s_store_sk = cs.c_current_addr_sk
LEFT JOIN 
    CustomerReturns cr ON cs.c_customer_sk = cr.wr_returning_customer_sk
JOIN 
    TopSales ts ON ws.w_warehouse_sk = ts.web_site_sk
WHERE 
    ts.total_net_paid > (SELECT AVG(total_net_paid) FROM TopSales)
ORDER BY 
    ts.total_net_paid DESC;
