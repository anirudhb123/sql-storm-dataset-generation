
WITH RECURSIVE Sales_Rank AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        ws.net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS profit_rank
    FROM
        web_sales ws
    WHERE
        ws.sold_date_sk BETWEEN 1 AND 100
    UNION ALL
    SELECT
        ws.web_site_sk,
        ws.web_name,
        ws.net_profit + 10000.00 * (CASE WHEN ws.sold_date_sk % 2 = 0 THEN 1 ELSE -1 END) AS net_profit,
        profit_rank
    FROM
        web_sales ws
    JOIN Sales_Rank sr ON ws.web_site_sk = sr.web_site_sk
    WHERE
        sr.profit_rank < 10
),
Aggregate_Results AS (
    SELECT
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(ws.net_profit, 0)) AS total_net_profit,
        STRING_AGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, ', ') AS customer_names,
        AVG(ws.net_profit) OVER (PARTITION BY ca.ca_city) AS average_profit
    FROM
        customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ca.ca_country IS NULL OR ca.ca_country <> 'USA'
    GROUP BY
        ca.ca_city
)
SELECT
    ar.ca_city,
    ar.customer_count,
    ar.total_net_profit,
    CASE
        WHEN ar.customer_count > 0 THEN ar.total_net_profit / ar.customer_count
        ELSE NULL
    END AS average_net_profit_per_customer,
    CASE
        WHEN ar.average_profit > 500000 THEN 'High'
        WHEN ar.average_profit BETWEEN 100000 AND 500000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM
    Aggregate_Results ar
JOIN
    (SELECT DISTINCT ws.web_site_sk FROM web_sales ws JOIN Sales_Rank sr ON ws.net_profit = sr.net_profit) AS ranked_websites
ON ar.total_net_profit > 0 
ORDER BY
    ar.total_net_profit DESC;
