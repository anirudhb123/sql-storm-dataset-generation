
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM
        customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN household_demographics hd ON d.cd_demo_sk = hd.hd_demo_sk
)
SELECT
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.buy_potential,
    COALESCE(rs.total_profit, 0) AS total_profit,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = cd.c_customer_sk) AS store_sales_count
FROM
    CustomerDemographics cd
LEFT JOIN RankedSales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
WHERE
    (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
    AND (rs.rnk <= 5 OR rs.rnk IS NULL)
ORDER BY
    total_profit DESC
LIMIT 100
UNION ALL
SELECT
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.buy_potential,
    COALESCE(rs.total_profit, 0) AS total_profit,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = cd.c_customer_sk) AS catalog_sales_count
FROM
    CustomerDemographics cd
LEFT JOIN RankedSales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
WHERE
    (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
    AND (rs.rnk <= 10 OR rs.rnk IS NULL)
ORDER BY
    total_profit DESC
LIMIT 100;
