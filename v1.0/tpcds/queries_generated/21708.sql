
WITH ranked_sales AS (
    SELECT
        ws.bill_customer_sk,
        ws.item_sk,
        SUM(ws.net_paid_inc_tax) AS total_paid,
        COUNT(*) OVER (PARTITION BY ws.bill_customer_sk, ws.item_sk ORDER BY ws.sold_date_sk DESC) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_paid_inc_tax) DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws.bill_customer_sk, ws.item_sk
),
customer_info AS (
    SELECT
        c.customer_sk,
        cd.gender,
        cd.marital_status,
        (CASE
            WHEN cd.purchase_estimate IS NULL THEN 'UNKNOWN'
            ELSE (CASE 
                WHEN cd.purchase_estimate > 5000 THEN 'HIGH SPENDER'
                WHEN cd.purchase_estimate BETWEEN 1000 AND 5000 THEN 'MEDIUM SPENDER'
                ELSE 'LOW SPENDER'
            END)
        END) AS spending_category
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
),
inventory_summary AS (
    SELECT
        inv.item_sk,
        SUM(inv.quantity_on_hand) AS total_quantity
    FROM
        inventory inv
    GROUP BY
        inv.item_sk
)
SELECT
    ci.customer_sk,
    ci.gender,
    ci.marital_status,
    ci.spending_category,
    rs.item_sk,
    rs.total_paid,
    rs.purchase_count,
    isum.total_quantity,
    CASE 
        WHEN rs.rank <= 5 THEN 'TOP_BUYER'
        ELSE 'REGULAR_BUYER'
    END AS buyer_category
FROM
    customer_info ci
JOIN
    ranked_sales rs ON ci.customer_sk = rs.bill_customer_sk
LEFT JOIN
    inventory_summary isu ON rs.item_sk = isu.item_sk
WHERE
    isu.total_quantity IS NOT NULL
    AND ci.gender IS NOT NULL
    AND ci.spending_category IS NOT NULL
ORDER BY
    ci.customer_sk,
    rs.total_paid DESC;
