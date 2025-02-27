
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        ws_net_profit,
        ws_quantity,
        CASE 
            WHEN ws_net_profit IS NULL THEN 'Unknown Profit'
            ELSE CASE 
                WHEN ws_net_profit > 0 THEN 'Profitable'
                WHEN ws_net_profit = 0 THEN 'Break-even'
                WHEN ws_net_profit < 0 THEN 'Loss'
            END
        END AS profit_status
    FROM web_sales
),
high_value_sales AS (
    SELECT 
        date_dim.d_date AS sale_date,
        customers.c_customer_id,
        sales.ws_item_sk,
        sales.ws_net_profit,
        sales.profit_status
    FROM ranked_sales sales
    JOIN date_dim ON sales.ws_sold_date_sk = date_dim.d_date_sk
    LEFT JOIN customer customers ON customers.c_customer_sk = (
        SELECT MIN(c_customer_sk) 
        FROM web_sales 
        WHERE ws_item_sk = sales.ws_item_sk
    )
    WHERE sales.price_rank = 1 AND sales.ws_quantity > 5
),
store_sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss_ticket_number) AS total_sales_count,
        AVG(ss_list_price) AS avg_list_price
    FROM store_sales
    GROUP BY ss_store_sk
),
promotion_analysis AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales ws
    INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_name
),
final_report AS (
    SELECT 
        s_store.sk AS store_id,
        COALESCE(hvs.sale_date, 'No Sales') AS sale_date,
        hvs.c_customer_id,
        COALESCE(sales_summary.total_net_paid, 0) AS store_net_sales,
        COALESCE(promos.order_count, 0) AS promo_order_count,
        COALESCE(promos.total_profit, 0) AS promo_total_profit 
    FROM store s
    LEFT JOIN high_value_sales hvs ON s.s_store_sk = hvs.ws_item_sk
    LEFT JOIN store_sales_summary sales_summary ON s.s_store_sk = sales_summary.ss_store_sk
    LEFT JOIN promotion_analysis promos ON hvs.ws_item_sk = promos.order_count
)
SELECT 
    store_id,
    sale_date,
    c_customer_id,
    store_net_sales,
    promo_order_count,
    promo_total_profit
FROM final_report
WHERE (sale_date IS NOT NULL OR store_net_sales > 0)
ORDER BY store_net_sales DESC, sale_date
LIMIT 100;
