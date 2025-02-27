
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_net_profit IS NOT NULL
),
CustomerOrderStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
ReturnStats AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        AVG(wr_return_amt) AS avg_return_amt
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(COALESCE(cs.cs_net_profit, 0)) AS total_catalog_sales,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_sales,
    COALESCE(cs_rank.total_catalog_sales_rank, 'N/A') AS catalog_sales_ranking,
    COALESCE(ws_rank.total_web_sales_rank, 'N/A') AS web_sales_ranking
FROM
    customer_address ca
LEFT JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN (
    SELECT
        ca.ca_state,
        SUM(cs.cs_net_profit) AS total_catalog_sales_rank
    FROM
        customer_address ca
    JOIN
        catalog_sales cs ON cs.cs_bill_customer_sk = (
            SELECT
                c.c_customer_sk
            FROM
                customer c
            WHERE
                c.c_current_addr_sk = ca.ca_address_sk
        )
    GROUP BY
        ca.ca_state
) cs_rank ON ca.ca_state = cs_rank.ca_state
LEFT JOIN (
    SELECT
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_web_sales_rank
    FROM
        customer_address ca
    JOIN
        web_sales ws ON ws.ws_bill_customer_sk = (
            SELECT
                c.c_customer_sk
            FROM
                customer c
            WHERE
                c.c_current_addr_sk = ca.ca_address_sk
        )
    GROUP BY
        ca.ca_state
) ws_rank ON ca.ca_state = ws_rank.ca_state
WHERE
    ca.ca_city IS NOT NULL
GROUP BY
    ca.ca_city, ca.ca_state
HAVING
    COUNT(DISTINCT c.c_customer_sk) > 0
ORDER BY
    total_web_sales DESC NULLS LAST, total_catalog_sales DESC;
