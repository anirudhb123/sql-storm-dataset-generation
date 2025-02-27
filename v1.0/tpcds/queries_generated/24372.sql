
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_profit DESC) AS rn
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year IS NOT NULL
        AND c.c_preferred_cust_flag = 'Y'
),
AggregateReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS unique_orders
    FROM
        web_returns
    WHERE
        wr_returned_date_sk IS NOT NULL
    GROUP BY
        wr_returning_customer_sk
)

SELECT
    ca.ca_city,
    COALESCE(SUM(rd.total_returned), 0) AS total_returns,
    AVG(ws.total_net_profit) AS avg_net_profit,
    CASE
        WHEN COUNT(DISTINCT ws_item_sk) = 0 THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM
    customer_address ca
LEFT JOIN
    RankedSales rs ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = rs.web_site_sk)
LEFT JOIN
    AggregateReturns rd ON rs.web_site_sk = rd.wr_returning_customer_sk
LEFT JOIN
    (SELECT
        web_site_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
     FROM
         web_sales
     GROUP BY
         web_site_sk) AS ws ON rs.web_site_sk = ws.web_site_sk
WHERE
    ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY
    ca.ca_city
HAVING
    SUM(rd.total_returned) IS NULL OR MAX(ws.order_count) > 1
ORDER BY
    ca.ca_city DESC
LIMIT 10;
