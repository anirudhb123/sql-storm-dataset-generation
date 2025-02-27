
WITH SalesData AS (
    SELECT
        w.w_warehouse_id,
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND d.d_moy BETWEEN 1 AND 6
    GROUP BY
        w.w_warehouse_id,
        c.c_customer_id
), 
RankedSales AS (
    SELECT
        w_id,
        c_id,
        total_quantity,
        total_profit,
        order_count,
        RANK() OVER (PARTITION BY w_id ORDER BY total_profit DESC) AS profit_rank
    FROM
        (SELECT
            warehouse_id AS w_id,
            customer_id AS c_id,
            total_quantity,
            total_profit,
            order_count
        FROM
            SalesData) AS sales_summary
)
SELECT
    r.w_id,
    r.c_id,
    r.total_quantity,
    r.total_profit,
    r.order_count
FROM
    RankedSales r
WHERE
    r.profit_rank <= 10
ORDER BY
    r.w_id, 
    r.total_profit DESC;
