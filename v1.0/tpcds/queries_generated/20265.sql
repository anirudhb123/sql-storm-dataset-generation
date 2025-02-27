
WITH RECURSIVE customer_return_stats AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_items,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
earned_discount AS (
    SELECT
        ws_bill_customer_sk,
        SUM(Ws_ext_discount_amt) AS total_discount
    FROM
        web_sales
    WHERE
        ws_net_paid > (CASE WHEN ws_net_paid_inc_tax < 0 THEN 0 ELSE ws_net_paid_inc_tax END)
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    ca_city,
    SUM(CASE WHEN cd_gender = 'M' THEN total_returns ELSE 0 END) AS male_returns,
    SUM(CASE WHEN cd_gender = 'F' THEN total_returns ELSE 0 END) AS female_returns,
    SUM(CASE WHEN cs_ext_discount_amt IS NULL THEN 0 ELSE total_discount END) AS total_discounted_sales
FROM
    customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_return_stats cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN earned_discount ed ON c.c_customer_sk = ed.ws_bill_customer_sk
WHERE
    ca_state IN ('NY', 'CA') AND
    (cd_marital_status = 'M' OR (cd_marital_status = 'S' AND cd_dep_count > 2))
GROUP BY
    ca_city
HAVING
    SUM(CASE WHEN total_returned_items > 0 THEN total_returned_items END) IS NOT NULL
ORDER BY
    ca_city,
    female_returns DESC NULLS LAST;
