
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        co.c_customer_sk,
        co.c_first_name,
        co.c_last_name,
        co.total_quantity,
        co.total_net_profit,
        DENSE_RANK() OVER (ORDER BY co.total_net_profit DESC) AS rank
    FROM 
        CustomerOrders co
    WHERE 
        co.total_net_profit > 1000
),
RecentReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
    GROUP BY 
        wr.wr_returning_customer_sk
),
CustomerReturnStats AS (
    SELECT 
        hc.c_customer_sk,
        hc.c_first_name,
        hc.c_last_name,
        COALESCE(rr.return_count, 0) AS return_count,
        COALESCE(rr.total_return_amt, 0) AS total_return_amt
    FROM 
        HighValueCustomers hc
    LEFT JOIN 
        RecentReturns rr ON hc.c_customer_sk = rr.wr_returning_customer_sk
)
SELECT 
    crs.c_customer_sk,
    crs.c_first_name,
    crs.c_last_name,
    crs.total_quantity,
    crs.total_net_profit,
    crs.return_count,
    crs.total_return_amt,
    CASE 
        WHEN crs.return_count > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_returned
FROM 
    CustomerReturnStats crs
ORDER BY 
    crs.total_net_profit DESC,
    crs.return_count ASC
LIMIT 50;
