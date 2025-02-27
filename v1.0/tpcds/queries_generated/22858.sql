
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S')
    GROUP BY ws.ws_item_sk
), filtered_sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        s.total_net_profit
    FROM sales_summary s
    WHERE s.rn <= 10
), product_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_color,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_current_price
    FROM item i
    LEFT JOIN income_band ib ON ib.ib_income_band_sk = (
        SELECT 
            hd.hd_income_band_sk
        FROM household_demographics hd
        JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
        WHERE c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_buy_potential = 'High')
        LIMIT 1
    )
), product_sales AS (
    SELECT 
        p.i_item_sk,
        p.i_item_desc,
        p.i_color,
        p.ib_lower_bound,
        p.ib_upper_bound,
        COALESCE(f.total_quantity, 0) AS total_quantity,
        COALESCE(f.total_sales, 0) AS total_sales,
        COALESCE(f.total_net_profit, 0) AS total_net_profit
    FROM product_info p
    LEFT JOIN filtered_sales f ON p.i_item_sk = f.ws_item_sk
)
SELECT 
    p.i_item_desc,
    p.total_quantity,
    p.total_sales,
    p.total_net_profit,
    CASE 
        WHEN p.total_sales = 0 THEN 'No Sales'
        WHEN p.total_sales BETWEEN p.ib_lower_bound AND p.ib_upper_bound THEN 'In Income Band'
        ELSE 'Out of Income Band'
    END AS income_band_status,
    CONCAT('Product: ', p.i_item_desc, ' | Sales: $', ROUND(p.total_sales, 2), 
           ' | Status: ', 
           CASE 
              WHEN p.total_net_profit > 0 THEN 'Profitable' 
              ELSE 'Not Profitable' 
           END) AS detailed_info
FROM product_sales p
ORDER BY p.total_net_profit DESC NULLS LAST;
