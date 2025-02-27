
WITH AddressCount AS (
    SELECT
        ca_city,
        COUNT(*) AS address_count
    FROM
        customer_address
    GROUP BY
        ca_city
),
CustomerCount AS (
    SELECT
        ca_city,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY
        ca_city
),
Demographics AS (
    SELECT
        cd.cd_gender,
        COUNT(c.c_customer_id) AS gender_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
),
SalesSummary AS (
    SELECT
        t_month_seq,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM
        store_sales
    JOIN
        date_dim dd ON ss_sold_date_sk = d_date_sk
    GROUP BY
        t_month_seq
)
SELECT
    ac.ca_city,
    ac.address_count,
    cc.customer_count,
    dm.cd_gender,
    dm.gender_count,
    ss.t_month_seq,
    ss.total_sales,
    ss.total_transactions
FROM
    AddressCount ac
LEFT JOIN
    CustomerCount cc ON ac.ca_city = cc.ca_city
LEFT JOIN
    Demographics dm ON TRUE
LEFT JOIN
    SalesSummary ss ON ss.t_month_seq IN (1, 2, 3)
ORDER BY
    ac.address_count DESC, cc.customer_count DESC, ss.total_sales DESC;
