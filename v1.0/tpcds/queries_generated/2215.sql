
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
HighNetProfitCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_net_profit,
        d.d_date,
        d.d_day_name,
        d.d_month_seq
    FROM 
        customer c
    INNER JOIN RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
    INNER JOIN date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = r.ws_bill_customer_sk)
    WHERE 
        r.profit_rank = 1
),
TopSalesItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        DENSE_RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS item_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
),
SalesWithReturnData AS (
    SELECT 
        ws.*,
        COALESCE(sr.return_quantity, 0) AS total_returns,
        COALESCE(cr.return_quantity, 0) AS catalog_returns 
    FROM 
        web_sales ws
    LEFT JOIN store_returns sr ON ws.ws_order_number = sr.sr_ticket_number AND ws.ws_item_sk = sr.sr_item_sk
    LEFT JOIN catalog_returns cr ON ws.ws_order_number = cr.cr_order_number AND ws.ws_item_sk = cr.cr_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    h.customer_total_profit,
    COALESCE(it.total_quantity_sold, 0) AS sold_quantity,
    (SUM(swd.ws_net_profit) OVER (PARTITION BY c.c_customer_id ORDER BY swd.ws_sold_date_sk DESC)) AS cumulative_net_profit,
    (CASE WHEN swd.total_returns > 0 THEN 'Returned Items Exist' ELSE 'No Returns' END) AS return_status
FROM 
    HighNetProfitCustomers h
INNER JOIN SalesWithReturnData swd ON h.c_customer_id = swd.ws_bill_customer_sk
LEFT JOIN TopSalesItems it ON swd.ws_item_sk = it.ws_item_sk AND it.item_rank <= 5
WHERE 
    h.total_net_profit IS NOT NULL
ORDER BY 
    h.total_net_profit DESC;
