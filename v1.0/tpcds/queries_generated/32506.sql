
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_order_number,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_item_sk) AS items_sold,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_order_number, ws_bill_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        ca.ca_state
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
return_data AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount,
        ROW_NUMBER() OVER (ORDER BY SUM(wr_return_quantity) DESC) AS return_rank
    FROM
        web_returns
    GROUP BY
        wr_item_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.customer_value,
    ci.ca_state,
    ss.total_sales,
    ss.items_sold,
    rd.total_returns,
    rd.total_return_amount
FROM
    customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN return_data rd ON ss.ws_order_number = rd.wr_order_number
WHERE
    ci.ca_state IS NOT NULL
    AND (rd.total_returns IS NULL OR rd.total_returns < 5)
ORDER BY
    ci.customer_value DESC,
    total_sales DESC;
