
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.web_site_sk) AS total_profit,
        CASE 
            WHEN DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) = 1 
            THEN 'Top Profit'
            ELSE 'Other'
        END AS profit_category
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
      AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),

ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Price Not Available'
            ELSE NULL
        END AS price_alert
    FROM item i
    WHERE i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CURRENT_DATE)
),

SalesSummary AS (
    SELECT 
        r.web_site_sk,
        COUNT(r.ws_order_number) AS total_orders,
        SUM(r.ws_sales_price * r.ws_quantity) AS total_sales,
        AVG(r.ws_sales_price) AS avg_sales_price,
        MAX(r.ws_sales_price) AS max_sales_price,
        COALESCE(MIN(r.ws_sales_price), 'No Sales') AS min_sales_price
    FROM web_sales r
    JOIN RankedSales rs ON r.ws_order_number = rs.ws_order_number
    GROUP BY r.web_site_sk
)

SELECT 
    ss.web_site_sk,
    ss.total_orders,
    ss.total_sales,
    ss.avg_sales_price,
    ss.max_sales_price,
    ss.min_sales_price,
    id.i_product_name,
    id.price_alert
FROM SalesSummary ss
LEFT JOIN ItemDetails id ON ss.web_site_sk = id.i_item_sk
WHERE ss.total_sales > (SELECT AVG(total_sales) FROM SalesSummary) 
OR EXISTS (
    SELECT 1 FROM web_returns wr 
    WHERE wr.wr_order_number = ss.total_orders AND wr.wr_return_quantity > 0
)
ORDER BY ss.total_sales DESC
LIMIT 10;
