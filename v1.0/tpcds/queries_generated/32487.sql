
WITH RECURSIVE SalesCTE AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        COUNT(ss_ticket_number) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS rn
    FROM
        store_sales
    GROUP BY
        ss_customer_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_first_name) AS city_rank
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_country = 'USA'
),
HighSpenders AS (
    SELECT
        s.ss_customer_sk,
        s.total_sales,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender
    FROM
        SalesCTE s
    JOIN CustomerInfo ci ON s.ss_customer_sk = ci.c_customer_sk
    WHERE
        s.purchase_count > 5
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    hs.total_sales,
    (SELECT COUNT(DISTINCT ws.web_page_sk)
     FROM web_sales ws
     WHERE ws.ws_bill_customer_sk = ci.c_customer_sk
    ) AS web_sales_count,
    COALESCE(hs.total_sales, 0) AS total_sales,
    CASE
        WHEN hs.total_sales > 1000 THEN 'High Roller'
        ELSE 'Regular'
    END AS customer_type,
    ci.city_rank
FROM
    CustomerInfo ci
LEFT JOIN HighSpenders hs ON ci.c_customer_sk = hs.ss_customer_sk
WHERE
    ci.city_rank <= 5
ORDER BY
    total_sales DESC, 
    ci.c_last_name ASC;
