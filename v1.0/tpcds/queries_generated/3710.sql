
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_id
), CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Estimate Unknown'
            ELSE CAST(cd.cd_purchase_estimate AS VARCHAR) 
        END AS purchase_estimate_status,
        hd.hd_income_band_sk
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), TopWebsites AS (
    SELECT
        web_site_id
    FROM RankedSales
    WHERE profit_rank <= 3
), ItemSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_item_profit
    FROM web_sales ws
    JOIN TopWebsites tw ON ws.ws_web_site_id = tw.web_site_id
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_quantity) > 100
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.purchase_estimate_status,
    SUM(is.total_quantity_sold) AS total_items_sold,
    SUM(is.total_item_profit) AS total_profit_from_top_items
FROM customer c
JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN ItemSales is ON c.c_customer_sk = is.ws_item_sk
WHERE cd.cd_marital_status = 'M'
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.purchase_estimate_status
ORDER BY total_profit_from_top_items DESC, total_items_sold DESC
FETCH FIRST 10 ROWS ONLY;
