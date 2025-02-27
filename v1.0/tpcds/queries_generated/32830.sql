
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year >= 1980
    GROUP BY ws.web_site_sk
), 
item_sales AS (
    SELECT 
        i.i_item_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS net_profit,
        (SUM(ws.ws_list_price) - SUM(ws.ws_ext_discount_amt)) AS gross_margin
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY i.i_item_sk
),
returns AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT 
    s.web_site_sk,
    s.total_sales,
    s.total_profit,
    i.order_count,
    i.net_profit,
    COALESCE(r.return_count, 0) AS return_count,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    (i.net_profit - COALESCE(r.total_return_amount, 0)) AS effective_net_profit
FROM sales_data s
JOIN item_sales i ON s.web_site_sk = i.i_item_sk
LEFT JOIN returns r ON i.i_item_sk = r.wr_item_sk
WHERE s.total_sales > 50
ORDER BY effective_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
