
WITH RankedWebSales AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM
        web_sales ws
    INNER JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1950 AND 2000
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        ws.web_site_sk
),
HighProfitWebSites AS (
    SELECT
        w.web_site_id,
        rw.total_quantity,
        rw.total_net_profit,
        CASE
            WHEN rw.total_net_profit IS NULL THEN 'No Profit'
            WHEN rw.total_net_profit < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_status
    FROM
        RankedWebSales rw
    JOIN
        web_site w ON rw.web_site_sk = w.web_site_sk
    WHERE
        rw.rank = 1
),
CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM
        store_sales ss
    JOIN
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_month IS NOT NULL
    GROUP BY
        c.c_customer_id
)
SELECT
    hw.web_site_id,
    hw.total_quantity,
    hw.total_net_profit,
    cs.total_spent,
    cs.total_transactions,
    COALESCE(hw.profit_status, 'No Sales') AS final_profit_status
FROM
    HighProfitWebSites hw
LEFT JOIN
    CustomerSales cs ON cs.total_spent > 1000
ORDER BY
    hw.total_net_profit DESC,
    cs.total_spent DESC
LIMIT 50;

