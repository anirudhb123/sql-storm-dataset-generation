
WITH SalesSummary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year >= 2021
    GROUP BY ws.ws_item_sk
),
TopSales AS (
    SELECT
        item.i_item_id,
        item.i_product_name,
        ss.total_quantity,
        ss.total_profit
    FROM SalesSummary ss
    JOIN item ON ss.ws_item_sk = item.i_item_sk
    WHERE ss.profit_rank <= 10
),
CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
    HAVING SUM(ws.ws_sales_price * ws.ws_quantity) > 1000
),
FinalReport AS (
    SELECT
        ts.i_item_id,
        ts.i_product_name,
        ts.total_quantity,
        ts.total_profit,
        cs.c_customer_id,
        cs.total_spent
    FROM TopSales ts
    FULL OUTER JOIN CustomerSales cs ON ts.total_profit > cs.total_spent
)
SELECT 
    COALESCE(ts.i_item_id, cs.c_customer_id) AS identifier,
    ts.i_product_name,
    ts.total_quantity,
    ts.total_profit,
    cs.total_spent
FROM FinalReport
WHERE (ts.total_profit IS NOT NULL OR cs.total_spent IS NOT NULL)
ORDER BY identifier ASC, total_profit DESC;
