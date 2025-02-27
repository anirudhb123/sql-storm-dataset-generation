
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS SalesRank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2458536 AND 2458538
),
CustomerReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS TotalReturns,
        SUM(wr.wr_return_amt_inc_tax) AS TotalAmountRefunded
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
),
StoreReturns AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS TotalReturns,
        SUM(sr.sr_return_amt_inc_tax) AS TotalAmountRefunded
    FROM
        store_returns sr
    GROUP BY
        sr.sr_item_sk
),
AllReturns AS (
    SELECT
        item_sk,
        COALESCE(SUM(TotalReturns), 0) AS TotalReturns,
        COALESCE(SUM(TotalAmountRefunded), 0) AS TotalAmountRefunded
    FROM (
        SELECT wr.wr_item_sk AS item_sk, TotalReturns, TotalAmountRefunded
        FROM CustomerReturns cr
        FULL OUTER JOIN (
            SELECT sr_returning_customer_sk AS item_sk,
                   TotalReturns,
                   TotalAmountRefunded
            FROM StoreReturns
        ) sr ON cr.wr_item_sk = sr.item_sk
    ) combinedReturns
    GROUP BY item_sk
)
SELECT
    cs.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS TotalSales,
    return_info.TotalReturns,
    return_info.TotalAmountRefunded,
    COUNT(DISTINCT ws.ws_order_number) AS OrderCount
FROM
    customer cs
JOIN
    customer_address ca ON cs.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN
    web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN
    AllReturns return_info ON ws.ws_item_sk = return_info.item_sk
WHERE
    ca.ca_state IN ('CA', 'TX')
    AND (return_info.TotalReturns > 0 OR return_info.TotalReturns IS NULL)
GROUP BY
    cs.c_customer_id,
    ca.ca_city,
    ca.ca_state
HAVING
    SUM(ws.ws_ext_sales_price) > 1000
ORDER BY
    TotalSales DESC,
    OrderCount DESC
LIMIT 100;
