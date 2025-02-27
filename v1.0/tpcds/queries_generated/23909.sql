
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(NULLIF(ws.ws_ext_discount_amt, 0), ws.ws_ext_sales_price * 0.10) AS effective_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
        AND ws.ws_net_paid_inc_tax IS NOT NULL
),
StoreProfitability AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_order_number) AS total_orders
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ss.s_store_sk
)
SELECT 
    s.s_store_name,
    COALESCE(RS.web_site_id, 'No Sales') AS web_site,
    SP.total_net_profit,
    RS.effective_discount,
    CASE 
        WHEN SP.total_net_profit IS NULL THEN 'Loss'
        WHEN SP.total_net_profit > 0 THEN 'Profit'
        ELSE 'Break-even'
    END AS profitability_status,
    STRING_AGG(DISTINCT RS.ws_order_number::text, ', ') AS order_numbers,
    AVG(RS.ws_sales_price) OVER (PARTITION BY s.s_store_sk) AS avg_price,
    (SELECT COUNT(*) FROM customer WHERE c_birth_year BETWEEN 1980 AND 2000) AS millennials_count
FROM 
    store s
LEFT JOIN RankedSales RS ON RS.web_site_id = s.s_store_id
JOIN StoreProfitability SP ON SP.s_store_sk = s.s_store_sk
GROUP BY 
    s.s_store_name, RS.web_site_id, SP.total_net_profit, RS.effective_discount
HAVING 
    (SP.total_net_profit > 1000 OR COUNT(RS.ws_order_number) > 5)
    AND COUNT(RS.ws_order_number) > 3
ORDER BY 
    avg_price DESC, s.s_store_name;
