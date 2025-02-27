
WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk,
        ws_item_sk
),
TopSellingItems AS (
    SELECT
        ws_item_sk,
        SUM(total_quantity) AS total_sold_quantity,
        SUM(total_net_profit) AS total_sold_net_profit
    FROM
        RankedSales
    WHERE
        rank <= 10
    GROUP BY
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    tsi.total_sold_quantity,
    tsi.total_sold_net_profit,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    DATE_ADD(d.d_date, INTERVAL 1 DAY) AS next_day
FROM 
    TopSellingItems tsi
JOIN 
    item i ON tsi.ws_item_sk = i.i_item_sk
JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    tsi.total_sold_net_profit DESC;
