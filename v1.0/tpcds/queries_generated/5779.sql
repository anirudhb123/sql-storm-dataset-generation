
WITH SalesSummary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM
        web_sales AS ws
    JOIN
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        d.d_year = 2023
        AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY
        d.d_year,
        d.d_month_seq,
        c.cd_gender
),
RankedSales AS (
    SELECT
        d_year,
        d_month_seq,
        cd_gender,
        total_net_profit,
        total_orders,
        unique_customers,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
    FROM
        SalesSummary
)
SELECT
    d_year,
    d_month_seq,
    cd_gender,
    total_net_profit,
    total_orders,
    unique_customers
FROM
    RankedSales
WHERE
    profit_rank = 1
ORDER BY
    d_year,
    d_month_seq;
