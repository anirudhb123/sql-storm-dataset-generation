
WITH RankedStores AS (
    SELECT 
        s_store_id,
        s_store_name,
        SUM(ss_net_profit) AS total_net_profit,
        RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS store_rank
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s_store_id, s_store_name
), DateRange AS (
    SELECT 
        d.d_date,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY d.d_date
), CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY cd_gender, cd_marital_status
)
SELECT 
    rs.store_id,
    rs.store_name,
    rs.total_net_profit,
    dr.total_orders,
    dr.total_sales,
    cs.gender,
    cs.marital_status,
    cs.customer_count,
    cs.total_sales AS demographic_sales
FROM RankedStores rs
JOIN DateRange dr ON dr.total_orders > 100
JOIN CustomerStats cs ON cs.total_sales > 1000
WHERE rs.store_rank <= 10
ORDER BY rs.total_net_profit DESC, dr.total_sales DESC;
