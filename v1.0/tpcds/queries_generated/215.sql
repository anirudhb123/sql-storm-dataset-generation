
WITH SalesSummary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM
        customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY
        cd_demo_sk, cd_gender, cd_marital_status, cd_income_band_sk
),
RankedItems AS (
    SELECT
        ss_item_sk,
        total_quantity_sold,
        total_sales,
        avg_net_profit,
        sales_rank
    FROM
        SalesSummary
    WHERE
        sales_rank <= 10  -- Top 10 items based on sales
)
SELECT
    c.cd_gender,
    c.cd_marital_status,
    COUNT(DISTINCT c.customer_count) AS total_customers,
    SUM(r.total_sales) AS total_sales_from_top_items,
    AVG(r.avg_net_profit) AS avg_net_profit_top_items
FROM
    CustomerDemographics c
LEFT JOIN
    RankedItems r ON c.cd_demo_sk = r.ws_item_sk  -- Joining with the top 10 ranked items
WHERE
    c.customer_count > (
        SELECT
            AVG(customer_count)
        FROM
            CustomerDemographics
    )
GROUP BY
    c.cd_gender, c.cd_marital_status
ORDER BY
    total_sales_from_top_items DESC
LIMIT 5;
