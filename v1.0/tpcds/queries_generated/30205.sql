
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
      AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY ws.web_site_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
),
reason_sales AS (
    SELECT 
        r.r_reason_desc,
        SUM(ws.ws_ext_sales_price) AS reason_sales
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    GROUP BY r.r_reason_desc
)
SELECT 
    s.web_site_sk, 
    s.total_sales, 
    s.total_orders,
    c.gender,
    c.hd_income_band_sk,
    COALESCE(r.reason_sales, 0) AS total_reason_sales,
    c.orders_count,
    c.total_spent
FROM sales_data s
JOIN customer_info c ON s.web_site_sk = (SELECT TOP 1 ws.ws_web_site_sk FROM web_sales ws WHERE c.orders_count = (SELECT COUNT(*) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk = c.c_customer_sk) AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) ORDER BY SUM(ws.ws_ext_sales_price) DESC)
LEFT JOIN reason_sales r ON r.reason_sales > 1000 
WHERE s.total_sales > 5000
ORDER BY s.total_sales DESC, c.total_spent DESC;
