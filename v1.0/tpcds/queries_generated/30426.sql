
WITH RECURSIVE TopProducts AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 100
),
ProductSales AS (
    SELECT
        i_item_id,
        i_item_desc,
        tp.total_quantity,
        WS.ws_sales_price,
        (tp.total_quantity * WS.ws_sales_price) AS total_revenue
    FROM TopProducts tp
    JOIN item i ON tp.ws_item_sk = i.i_item_sk
    JOIN web_sales WS ON tp.ws_item_sk = WS.ws_item_sk
),
SalesGrowth AS (
    SELECT
        d_year AS sales_year,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_profit) AS avg_profit_per_sale
    FROM web_sales WS
    JOIN date_dim D ON WS.ws_sold_date_sk = D.d_date_sk
    GROUP BY d_year
),
CustomerDemographics AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
),
FinalReport AS (
    SELECT
        pd.i_item_desc,
        pd.total_quantity,
        pd.total_revenue,
        sg.total_profit,
        sg.avg_profit_per_sale,
        cd.customer_count,
        cd.avg_purchase_estimate
    FROM ProductSales pd
    CROSS JOIN SalesGrowth sg
    LEFT JOIN CustomerDemographics cd ON cd.customer_count > 100
)
SELECT 
    item_desc,
    total_quantity,
    total_revenue,
    total_profit,
    avg_profit_per_sale,
    customer_count
FROM FinalReport
WHERE total_revenue > (SELECT AVG(total_revenue) FROM FinalReport)
ORDER BY total_revenue DESC
LIMIT 10;
