
WITH SalesData AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM
        web_sales AS ws
    JOIN
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
),
CustomerCount AS (
    SELECT
        ws.ws_web_page_sk,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM
        web_sales AS ws
    GROUP BY
        ws.ws_web_page_sk
),
InventoryStatus AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        inventory AS inv
    GROUP BY
        inv.inv_item_sk
)
SELECT
    sd.ws_web_page_sk,
    COUNT(DISTINCT sd.ws_item_sk) AS items_sold,
    SUM(sd.total_quantity) AS total_units_sold,
    SUM(sd.total_profit) AS total_revenue,
    cc.unique_customers,
    is.total_inventory
FROM
    SalesData AS sd
LEFT JOIN
    CustomerCount AS cc ON sd.ws_web_page_sk = cc.ws_web_page_sk
LEFT JOIN
    InventoryStatus AS is ON sd.ws_item_sk = is.inv_item_sk
GROUP BY
    sd.ws_web_page_sk, cc.unique_customers, is.total_inventory
ORDER BY
    total_revenue DESC
LIMIT 10;
