
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        cs.cs_order_number,
        ss.ss_ticket_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        cs.cs_sales_price,
        cs.cs_quantity,
        ss.ss_sales_price,
        ss.ss_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS ws_rank,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_sales_price DESC) AS cs_rank,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_ticket_number ORDER BY ss.ss_sales_price DESC) AS ss_rank
    FROM
        web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number OR cs.cs_order_number = ss.ss_ticket_number
)
SELECT
    ws.ws_order_number,
    cs.cs_order_number,
    ss.ss_ticket_number,
    SUM(ws.ws_quantity) AS total_ws_quantity,
    SUM(cs.cs_quantity) AS total_cs_quantity,
    SUM(ss.ss_quantity) AS total_ss_quantity,
    AVG(ws.ws_sales_price) AS avg_ws_sales_price,
    AVG(cs.cs_sales_price) AS avg_cs_sales_price,
    AVG(ss.ss_sales_price) AS avg_ss_sales_price
FROM
    RankedSales
WHERE
    ws_rank = 1 OR cs_rank = 1 OR ss_rank = 1
GROUP BY
    ws.ws_order_number, cs.cs_order_number, ss.ss_ticket_number
ORDER BY
    total_ws_quantity DESC, total_cs_quantity DESC, total_ss_quantity DESC
LIMIT 50;
