
WITH SalesSummary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023 AND dd.d_month_seq IN (5, 6, 7) 
        AND (ws.ws_ship_mode_sk IS NULL OR (ws.ws_net_paid > 0 AND ws.ws_ext_discount_amt < 0))
    GROUP BY
        ws.ws_item_sk
),
TopSales AS (
    SELECT
        ss.ws_item_sk,
        ss.total_sales_quantity,
        ss.total_sales_amount,
        ss.total_orders
    FROM
        SalesSummary ss
    WHERE
        ss.sales_rank <= 10 
)
SELECT
    i.i_item_id,
    COALESCE(t.total_sales_quantity, 0) AS quantity_sold,
    COALESCE(t.total_sales_amount, 0) AS sales_amount,
    (SELECT COUNT(DISTINCT c.c_customer_sk)
     FROM customer c 
     WHERE c.c_current_cdemo_sk IS NOT NULL 
     AND c.c_first_shipto_date_sk = (SELECT MIN(c.c_first_shipto_date_sk) FROM customer)
    ) AS distinct_customers,
    COUNT(DISTINCT CASE WHEN wd.w_web_page_sk IS NOT NULL THEN wd.w_web_page_sk ELSE NULL END) AS distinct_webpages
FROM
    item i
LEFT JOIN
    TopSales t ON i.i_item_sk = t.ws_item_sk
LEFT JOIN
    web_page wd ON wd.wp_web_page_sk = (SELECT MIN(wp.wp_web_page_sk) FROM web_page wp WHERE wp.wp_web_page_id IS NOT NULL)
GROUP BY
    i.i_item_id, t.total_sales_quantity, t.total_sales_amount
HAVING
    (SUM(COALESCE(t.total_sales_quantity, 0)) > 100 OR SUM(COALESCE(t.total_sales_amount, 0)) > 5000)
ORDER BY
    sales_amount DESC
LIMIT 20;
