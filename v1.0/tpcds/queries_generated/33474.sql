
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws.web_class,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
    GROUP BY ws.web_site_sk, ws.web_name, ws.web_class
),
TopWebsites AS (
    SELECT 
        web_site_sk,
        web_name,
        web_class,
        total_net_profit 
    FROM SalesHierarchy
    WHERE rank <= 5
),
Returns AS (
    SELECT 
        wr.returning_customer_sk,
        COUNT(wr.return_order_number) AS total_returns,
        SUM(wr.net_loss) AS total_loss
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY wr.returning_customer_sk
),
CustomerReturnInfo AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_loss, 0) AS total_loss,
        COUNT(CASE WHEN r.total_returns > 0 THEN 1 END) OVER() AS count_of_return_customers
    FROM customer c
    LEFT JOIN Returns r ON c.c_customer_sk = r.returning_customer_sk
)
SELECT 
    tw.web_name,
    tw.web_class,
    tw.total_net_profit,
    cri.total_returns,
    cri.total_loss,
    cri.count_of_return_customers
FROM TopWebsites tw
LEFT JOIN CustomerReturnInfo cri ON tw.web_site_sk = cri.c_customer_sk
ORDER BY tw.total_net_profit DESC, cri.total_loss DESC;
