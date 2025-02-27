
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr_order_number) AS web_order_count,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned,
        COUNT(DISTINCT CASE WHEN wr_order_number IS NOT NULL THEN wr_order_number END) AS distinct_web_orders,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws_net_profit) AS median_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN 
        RankedReturns r ON c.c_customer_sk = r.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
ItemProfit AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
    HAVING 
        SUM(ws.ws_net_profit) IS NOT NULL
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.web_order_count,
    cs.total_returned,
    cs.distinct_web_orders,
    ip.i_item_sk,
    COALESCE(ip.total_profit, 0) AS total_profit,
    CASE 
        WHEN ip.order_count IS NULL THEN 'No Orders' 
        ELSE 'Orders Present' 
    END AS order_status,
    COALESCE(NULLIF(cs.median_profit, 0), 'Unknown') AS adjusted_median_profit
FROM 
    customer c
JOIN 
    CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    ItemProfit ip ON ip.order_count > 0 
WHERE 
    c.c_birth_year > 1980 
    AND c.c_current_addr_sk IS NOT NULL 
    AND (c.c_pref_cust_flag = 'Y' OR c.c_first_name LIKE 'A%')
ORDER BY 
    cs.total_returned DESC,
    c.c_last_name ASC;
