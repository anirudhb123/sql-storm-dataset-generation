
WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM
        web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_current_price > 20
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_item_sk
),
top_sales AS (
    SELECT
        ca.ca_city,
        SUM(sd.total_quantity) AS total_qty,
        AVG(sd.total_profit) AS avg_profit
    FROM
        customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN sales_data sd ON sd.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        ca.ca_city
    HAVING
        SUM(sd.total_quantity) > 100
)
SELECT
    ts.ca_city,
    ts.total_qty,
    ts.avg_profit,
    CASE  
        WHEN ts.avg_profit IS NOT NULL THEN 'Profitable'
        ELSE 'No Sales'
    END AS sales_status
FROM
    top_sales ts
WHERE
    ts.total_qty > (
        SELECT 
            AVG(total_qty)
        FROM 
            top_sales
    )
ORDER BY
    ts.total_qty DESC;
