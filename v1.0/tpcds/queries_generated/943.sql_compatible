
WITH CustomerReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM
        store_returns
    GROUP BY
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cr.total_return_quantity) AS total_returns
    FROM
        customer c
    JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY
        total_returns DESC
    LIMIT 10
),
SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM
        web_sales ws
),
RecentSales AS (
    SELECT
        sd.ws_item_sk,
        sd.ws_net_profit
    FROM
        SalesData sd
    WHERE
        sd.rn = 1
),
ItemPerformance AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        COALESCE(RSUM.total_return_amount, 0) AS total_return_amount,
        COALESCE(SUM(sd.ws_net_profit), 0) AS total_sales_profit
    FROM
        item i
    LEFT JOIN
        CustomerReturns RSUM ON i.i_item_sk = RSUM.sr_item_sk
    LEFT JOIN
        RecentSales sd ON i.i_item_sk = sd.ws_item_sk
    GROUP BY
        i.i_item_id, i.i_item_desc
)
SELECT
    ic.c_first_name,
    ic.c_last_name,
    ip.i_item_id,
    ip.i_item_desc,
    ip.total_return_amount,
    ip.total_sales_profit,
    CASE 
        WHEN ip.total_return_amount > ip.total_sales_profit THEN 'Review'
        ELSE 'Good Standing'
    END AS status
FROM
    TopCustomers ic
JOIN
    ItemPerformance ip ON ic.c_customer_sk IN (SELECT cr.sr_customer_sk FROM CustomerReturns cr WHERE cr.sr_item_sk = ip.i_item_sk)
ORDER BY
    ip.total_sales_profit DESC, ip.total_return_amount ASC;
