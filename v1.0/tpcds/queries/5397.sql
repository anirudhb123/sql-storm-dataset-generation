
WITH SalesSummary AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM
        catalog_sales cs
    JOIN
        date_dim dd ON dd.d_date_sk = cs.cs_sold_date_sk
    WHERE
        dd.d_year = 2023 AND
        dd.d_month_seq BETWEEN 9 AND 12
    GROUP BY
        cs.cs_item_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM
        customer_demographics cd
    JOIN
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
),
TopItems AS (
    SELECT
        ss.cs_item_sk,
        ss.total_quantity,
        ss.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM
        SalesSummary ss
)
SELECT
    ci.i_item_id,
    ci.i_product_name,
    ci.i_category,
    ci.i_brand,
    items.total_quantity,
    items.total_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    income.ib_lower_bound,
    income.ib_upper_bound
FROM
    TopItems items
JOIN
    item ci ON ci.i_item_sk = items.cs_item_sk
JOIN
    CustomerDemographics cd ON cd.cd_demo_sk = (SELECT DISTINCT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = items.cs_item_sk)
JOIN
    income_band income ON income.ib_income_band_sk = (SELECT DISTINCT hd.hd_income_band_sk FROM household_demographics hd WHERE hd.hd_demo_sk = cd.cd_demo_sk)
WHERE
    items.rank <= 10
ORDER BY
    items.total_net_profit DESC;
