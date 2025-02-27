
WITH RankedReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(sr_ticket_number) AS return_count,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependencies,
        COALESCE(cd.cd_purchase_estimate, 0) AS estimated_spending,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
TopCustomers AS (
    SELECT
        rd.sold_date,
        rd.customer_sk,
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.dependencies,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
    JOIN
        (SELECT
            ws_bill_customer_sk AS customer_sk,
            d_date AS sold_date
        FROM
            date_dim
        JOIN
            web_sales ON d_date_sk = ws_sold_date_sk
        WHERE
            d_date BETWEEN '2022-01-01' AND '2022-12-31') rd
    ON
        ws.ws_bill_customer_sk = rd.customer_sk
    JOIN
        CustomerDetails cd ON cd.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY
        rd.sold_date, rd.customer_sk, cd.c_customer_id, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.dependencies
)
SELECT
    tc.sold_date,
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tr.total_returned_quantity, 0) AS total_returned,
    COALESCE(tr.return_count, 0) AS returns_count,
    tc.total_profit,
    CASE
        WHEN tc.total_profit > 1000 THEN 'High Value'
        WHEN tc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM
    TopCustomers tc
LEFT JOIN
    RankedReturns tr ON tc.customer_sk = tr.sr_customer_sk
WHERE
    EXISTS (
        SELECT 1
        FROM store s
        WHERE s.s_store_sk = (
            SELECT ss_store_sk
            FROM store_sales ss
            WHERE ss.ss_customer_sk = tc.customer_sk
            GROUP BY ss.s_store_sk
            HAVING SUM(ss.ss_net_profit) > 50
            LIMIT 1
        )
    )
ORDER BY
    tc.total_profit DESC, tc.sold_date;
