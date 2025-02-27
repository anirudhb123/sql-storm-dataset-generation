
WITH SalesData AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        WS_EXT_SALES_PRICE,
        ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_ship_date_sk DESC) AS rn,
        ws_ext_discount_amt,
        wb.net_profit AS wb_net_profit
    FROM
        web_sales
    JOIN
        web_site ON ws_web_site_sk = web_site_sk
    JOIN
        customer ON ws_bill_customer_sk = c_customer_sk
    LEFT JOIN (
        SELECT
            ws_item_sk,
            SUM(ws_net_profit) AS net_profit
        FROM
            web_sales
        GROUP BY
            ws_item_sk
    ) AS wb ON ws_item_sk = wb.ws_item_sk
    WHERE
        ws_sales_price > 100
),
RecentSales AS (
    SELECT
        sd.ws_bill_customer_sk,
        sd.ws_item_sk,
        SUM(sd.ws_ext_sales_price) AS total_sales,
        MAX(sd.ws_ext_discount_amt) AS max_discount,
        COUNT(*) AS total_transactions
    FROM
        SalesData sd
    WHERE
        sd.rn <= 10
    GROUP BY
        sd.ws_bill_customer_sk, sd.ws_item_sk
)
SELECT
    cs.cd_gender,
    SUM(rs.total_sales) AS total_sales_by_gender,
    AVG(rs.max_discount) AS average_discount,
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count
FROM
    RecentSales rs
JOIN
    customer_demographics cs ON cs.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = rs.ws_bill_customer_sk)
GROUP BY
    cs.cd_gender
ORDER BY
    total_sales_by_gender DESC
FETCH FIRST 5 ROWS ONLY;
