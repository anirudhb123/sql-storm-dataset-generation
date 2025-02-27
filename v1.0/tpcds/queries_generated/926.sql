
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_current_price > 50
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender IS NOT NULL AND cd.cd_income_band_sk IS NOT NULL
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
HighProfitSales AS (
    SELECT
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        cd.cd_income_band_sk,
        cd.cd_gender
    FROM
        SalesData sd
    JOIN
        CustomerDemographics cd ON cd.cd_demo_sk = (
            SELECT
                c.c_current_cdemo_sk
            FROM
                customer c
            WHERE
                c.c_current_addr_sk IS NOT NULL
            LIMIT 1
        )
    WHERE
        sd.total_net_profit > (
            SELECT
                AVG(total_net_profit) 
            FROM
                SalesData
        )
)
SELECT
    d.d_date,
    h.Item,
    COALESCE(SUM(h.total_net_profit), 0) AS total_net_profit,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    CASE 
        WHEN COUNT(DISTINCT c.c_customer_sk) > 50 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level
FROM
    date_dim d
LEFT JOIN
    HighProfitSales h ON d.d_date_sk = h.ws_sold_date_sk
LEFT JOIN
    customer c ON c.c_current_cdemo_sk IS NOT NULL
WHERE
    d.d_year = 2023
GROUP BY
    d.d_date, h.Item
ORDER BY
    total_net_profit DESC
LIMIT 10;
