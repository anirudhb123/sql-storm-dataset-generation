
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS ItemRank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
CustomerReturns AS (
    SELECT
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS TotalReturns,
        SUM(wr.wr_return_amount) AS TotalReturnAmount
    FROM
        web_returns wr
    WHERE
        wr.wr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        wr.wr_returning_customer_sk
),
StoreSalesSummary AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS TotalStoreProfit,
        COUNT(DISTINCT ss.ss_ticket_number) AS TotalTransactions
    FROM
        store_sales ss
    GROUP BY
        ss.ss_store_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS TotalCustomers,
    AVG(rs.ws_sales_price) AS AvgSalesPrice,
    SUM(COALESCE(cr.TotalReturnAmount, 0)) AS TotalReturns,
    SUM(sss.TotalStoreProfit) AS TotalStoreProfit
FROM
    customer_address ca
LEFT JOIN
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN
    RankedSales rs ON rs.ws_item_sk IN (SELECT cr_item_sk FROM catalog_returns)
LEFT JOIN 
    CustomerReturns cr ON cr.wr_returning_customer_sk = c.c_customer_sk
LEFT JOIN 
    StoreSalesSummary sss ON sss.ss_store_sk = (SELECT s_store_sk FROM store WHERE s_state = ca.ca_state LIMIT 1)
WHERE
    ca.ca_country = 'USA'
    AND (c.c_birth_month IS NULL OR c.c_birth_month != 7) 
GROUP BY
    ca.ca_city, ca.ca_state
HAVING
    COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY
    TotalCustomers DESC, AvgSalesPrice DESC NULLS LAST;
