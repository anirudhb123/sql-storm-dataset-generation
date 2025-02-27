
WITH SalesData AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        wc.cc_country AS country,
        date_dim.d_year AS sale_year
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    JOIN call_center cc ON c.c_current_addr_sk = cc.cc_call_center_sk
    WHERE date_dim.d_year BETWEEN 2020 AND 2023
    GROUP BY ws.ws_item_sk, wc.cc_country, date_dim.d_year
),
AggregatedData AS (
    SELECT
        item_sk,
        country,
        SUM(total_net_profit) AS aggregated_net_profit,
        AVG(total_quantity) AS average_quantity
    FROM SalesData
    GROUP BY item_sk, country
)
SELECT
    ad.item_sk,
    ad.country,
    ad.aggregated_net_profit,
    ad.average_quantity,
    item.i_brand,
    item.i_category,
    COUNT(DISTINCT cs_order_number) AS total_orders
FROM AggregatedData ad
JOIN item ON ad.item_sk = item.i_item_sk
LEFT JOIN catalog_sales cs ON ad.item_sk = cs.cs_item_sk
GROUP BY ad.item_sk, ad.country, ad.aggregated_net_profit, ad.average_quantity, item.i_brand, item.i_category
ORDER BY ad.aggregated_net_profit DESC, average_quantity DESC
LIMIT 100;
