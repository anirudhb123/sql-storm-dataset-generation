
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2458849 AND 2458913 -- Date range filter
    GROUP BY ss_store_sk, ss_item_sk
),
TopItems AS (
    SELECT 
        r.ss_store_sk,
        r.ss_item_sk,
        r.total_quantity,
        r.total_net_profit,
        d.d_date AS sale_date,
        ROW_NUMBER() OVER (PARTITION BY r.ss_store_sk ORDER BY r.total_net_profit DESC) AS rn
    FROM RankedSales r
    JOIN date_dim d ON r.ss_item_sk = d.d_date_sk
    WHERE r.sales_rank <= 5
),
SalesDetails AS (
    SELECT 
        t.ss_store_sk,
        t.ss_item_sk,
        t.total_quantity,
        t.total_net_profit,
        ca.ca_state,
        COALESCE(ct.cd_gender, 'Unknown') AS customer_gender,
        SUM(CASE WHEN t.total_net_profit > 1000 THEN 1 ELSE 0 END) AS high_profit_sales
    FROM TopItems t
    LEFT JOIN customer c ON c.c_customer_sk = t.ss_store_sk 
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY t.ss_store_sk, t.ss_item_sk, ca.ca_state, customer_gender
)
SELECT 
    ss.sd_store_sk,
    ss.ss_item_sk,
    ss.ca_state,
    ss.customer_gender,
    ss.total_quantity,
    ss.total_net_profit,
    CASE 
        WHEN ss.high_profit_sales > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_high_profit_sales
FROM SalesDetails ss
WHERE ss.total_net_profit > 0 -- Filter for positive net profit
ORDER BY ss.total_net_profit DESC, ss.total_quantity DESC
LIMIT 10;
