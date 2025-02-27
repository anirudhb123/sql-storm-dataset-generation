
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2458839 AND 2458845
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
), item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM item i
), customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), return_stats AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
)
SELECT 
    sd.ws_sold_date_sk,
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    sd.total_quantity,
    sd.total_net_paid,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    hd.hd_income_band_sk
FROM sales_data sd
JOIN item_details id ON sd.ws_item_sk = id.i_item_sk
LEFT JOIN return_stats rs ON sd.ws_item_sk = rs.wr_item_sk
JOIN customer_data cd ON cd.hd_income_band_sk IS NOT NULL
WHERE (sd.total_net_paid > 1000 OR sd.total_quantity > 5)
  AND (cd.cd_gender = 'F' OR cd.cd_marital_status != 'S')
  AND id.i_current_price IS NOT NULL
ORDER BY sd.ws_sold_date_sk, total_net_paid DESC;
