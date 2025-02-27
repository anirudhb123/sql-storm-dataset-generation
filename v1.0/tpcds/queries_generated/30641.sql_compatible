
WITH RECURSIVE SalesCTE AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM
        store_sales
    WHERE
        ss_sold_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ss_sold_date_sk, ss_item_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_last_name) AS cust_rank
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity_sold,
        COUNT(DISTINCT s.ss_ticket_number) AS transaction_count,
        AVG(s.ss_net_paid) AS avg_net_paid
    FROM
        store_sales s
    WHERE
        s.ss_store_sk IN (SELECT s_store_sk FROM store WHERE s_division_id = 1)
    GROUP BY
        s.ss_item_sk
),
FinalResults AS (
    SELECT
        sd.ss_item_sk,
        sd.total_quantity_sold,
        sd.transaction_count,
        sd.avg_net_paid,
        c.c_first_name,
        c.c_last_name,
        c.gender,
        c.marital_status,
        c.income_band,
        r.r_reason_desc,
        ROW_NUMBER() OVER (PARTITION BY sd.ss_item_sk ORDER BY sd.avg_net_paid DESC) AS rank_by_avg_net
    FROM
        SalesData sd
    JOIN CustomerDetails c ON c.cust_rank = 1
    LEFT JOIN reason r ON r.r_reason_sk IN (
        SELECT DISTINCT cr_reason_sk FROM catalog_returns WHERE cr_item_sk = sd.ss_item_sk
    )
)
SELECT
    fr.ss_item_sk,
    fr.total_quantity_sold,
    fr.transaction_count,
    fr.avg_net_paid,
    fr.c_first_name,
    fr.c_last_name,
    fr.gender,
    fr.marital_status,
    fr.income_band
FROM
    FinalResults fr
WHERE
    fr.rank_by_avg_net <= 10
ORDER BY
    fr.avg_net_paid DESC;
