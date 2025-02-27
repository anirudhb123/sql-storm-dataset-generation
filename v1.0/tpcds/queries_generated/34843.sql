
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk, ws_order_number
    HAVING SUM(ws_quantity) > 0
), 
address_cte AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state) AS full_address
    FROM customer_address
    WHERE ca_country = 'USA'
),
returns_summary AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
demographics_summary AS (
    SELECT 
        hd_income_band_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM household_demographics hd
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY hd_income_band_sk
)
SELECT 
    ws.item_sk,
    ws.total_quantity,
    ws.total_net_paid,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
    d.income_band_sk,
    ds.customer_count,
    ds.avg_purchase_estimate,
    a.full_address
FROM sales_cte ws 
LEFT JOIN returns_summary rs ON ws.ws_item_sk = rs.sr_item_sk
JOIN demographics_summary ds ON (ds.hd_income_band_sk = (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound <= (SELECT AVG(ws_net_paid) FROM sales_cte) AND ib_upper_bound > (SELECT AVG(ws_net_paid) FROM sales_cte)))
LEFT JOIN address_cte a ON a.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = (SELECT ws_ship_customer_sk FROM web_sales WHERE ws_order_number = ws.ws_order_number LIMIT 1))
WHERE ws.rank <= 10
ORDER BY ws.total_net_paid DESC;
