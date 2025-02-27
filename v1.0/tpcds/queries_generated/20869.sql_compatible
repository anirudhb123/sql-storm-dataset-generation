
WITH sales_data AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
returns_data AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
),
profit_data AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_net_paid) AS total_sales,
        COALESCE(rd.total_returned, 0) AS total_returns,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        SUM(sd.ws_net_paid) - COALESCE(rd.total_return_amount, 0) AS net_profit
    FROM
        sales_data sd
    LEFT JOIN
        returns_data rd ON sd.ws_item_sk = rd.wr_item_sk
    GROUP BY
        sd.ws_item_sk
),
ranked_profit AS (
    SELECT
        pd.ws_item_sk,
        pd.total_sales,
        pd.total_returns,
        pd.net_profit,
        RANK() OVER (ORDER BY pd.net_profit DESC) AS profit_rank
    FROM
        profit_data pd
)
SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    rp.ws_item_sk,
    rp.total_sales,
    rp.total_returns,
    rp.net_profit
FROM
    ranked_profit rp
JOIN
    customer c ON c.c_customer_sk = (SELECT MIN(cc.cc_call_center_sk) FROM call_center cc WHERE cc.cc_closed_date_sk IS NULL)
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    rp.profit_rank <= 10
    AND (ca.ca_city IS NOT NULL OR ca.ca_state IS NOT NULL)
ORDER BY
    rp.net_profit DESC;
