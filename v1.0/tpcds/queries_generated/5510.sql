
WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM
        catalog_sales cs
    JOIN
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
        AND i.i_manager_id IS NOT NULL
    GROUP BY
        d.d_year, d.d_month_seq, cs.cs_item_sk
),
monthly_sales AS (
    SELECT
        d_year,
        d_month_seq,
        SUM(total_quantity) AS total_quantity,
        SUM(total_sales) AS total_sales,
        SUM(total_profit) AS total_profit
    FROM
        sales_summary
    GROUP BY
        d_year, d_month_seq
),
ranked_sales AS (
    SELECT
        d_year,
        d_month_seq,
        total_quantity,
        total_sales,
        total_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
    FROM
        monthly_sales
)
SELECT
    rs.d_year,
    rs.d_month_seq,
    rs.total_quantity,
    rs.total_sales,
    rs.total_profit,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state
FROM
    ranked_sales rs
JOIN
    web_sales ws ON rs.d_year = YEAR(ws.ws_sold_date_sk) AND rs.d_month_seq = MONTH(ws.ws_sold_date_sk)
JOIN
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    rs.profit_rank <= 5
ORDER BY
    rs.d_year, rs.profit_rank;
