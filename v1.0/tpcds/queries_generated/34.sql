
WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        COALESCE(sr.sr_return_quantity, 0) AS total_returns,
        COALESCE(sr.sr_return_amt, 0) AS total_return_amount,
        ws.ws_wholesale_cost,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales AS ws
    LEFT JOIN store_returns AS sr ON ws.ws_order_number = sr.sr_ticket_number
    WHERE ws.ws_sold_date_sk BETWEEN (
        SELECT MAX(d.d_date_sk) - 30 FROM date_dim AS d
    ) AND (
        SELECT MAX(d.d_date_sk) FROM date_dim AS d
    )
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_credit_rating,
    IFNULL(sd.ws_sales_price, 0) AS last_sales_price,
    COALESCE(sd.total_returns, 0) AS returns_last_30_days,
    COALESCE(sd.total_return_amount, 0) AS return_amount_last_30_days,
    CASE
        WHEN cs.rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS customer_category
FROM customer_summary AS cs
LEFT JOIN sales_data AS sd ON cs.c_customer_sk = sd.ws_bill_customer_sk
WHERE sd.ws_sold_date_sk IS NOT NULL
ORDER BY total_spent DESC;
