
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank_per_order
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
),
HighProfitItems AS (
    SELECT 
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_quantity,
        r.ws_sales_price,
        r.ws_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.rank_per_order = 1
),
StoreSalesAggregated AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk >= 2450600
    GROUP BY 
        ss.ss_store_sk
),
SalesDetails AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(hpi.ws_net_profit), 0) AS total_web_sales_profit,
        COALESCE(aggregate.total_store_revenue, 0) AS total_store_revenue,
        (COALESCE(SUM(hpi.ws_net_profit), 0) - COALESCE(aggregate.total_store_revenue, 0)) AS profit_difference
    FROM 
        customer c
    LEFT JOIN 
        HighProfitItems hpi ON c.c_customer_sk = hpi.ws_item_sk
    LEFT JOIN 
        StoreSalesAggregated aggregate ON aggregate.ss_store_sk = c.c_current_addr_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    d.d_date,
    sd.total_web_sales_profit,
    sd.total_store_revenue,
    sd.profit_difference
FROM 
    SalesDetails sd
JOIN 
    customer c ON c.c_customer_id IN (SELECT DISTINCT c_customer_id FROM customer WHERE c_preferred_cust_flag = 'Y')
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim)
WHERE 
    sd.profit_difference > 0
ORDER BY 
    sd.profit_difference DESC
FETCH FIRST 50 ROWS ONLY;
