
WITH ranked_sales AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_cdemo_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
), 
highest_profit AS (
    SELECT 
        demo.cd_gender,
        demo.cd_marital_status,
        demo.cd_purchase_estimate,
        demo.cd_credit_rating,
        sales.total_profit
    FROM 
        customer_demographics demo
    JOIN 
        ranked_sales sales ON demo.cd_demo_sk = sales.ws_bill_cdemo_sk
    WHERE 
        sales.profit_rank = 1
), 
avg_return_stats AS (
    SELECT 
        AVG(sr_return_amt) AS avg_return_amt,
        COUNT(*) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_cdemo_sk
    HAVING 
        AVG(sr_return_amt) IS NOT NULL
), 
customer_address_info AS (
    SELECT 
        ca.country,
        SUM(COALESCE(returns.total_returns, 0)) AS total_return_count
    FROM 
        customer_address ca
    LEFT JOIN 
        (SELECT 
            sr.c_customer_sk,
            COUNT(*) AS total_returns
         FROM 
            store_returns sr
         GROUP BY 
            sr.c_customer_sk) returns ON ca.ca_address_sk = returns.c_customer_sk
    GROUP BY 
        ca.country
)
SELECT 
    demo.cd_gender,
    demo.cd_marital_status,
    demo.cd_purchase_estimate,
    demo.cd_credit_rating,
    addr.country,
    stats.avg_return_amt,
    stats.total_returns
FROM 
    highest_profit demo
JOIN 
    customer_address_info addr ON addr.total_return_count > 0
LEFT JOIN 
    avg_return_stats stats ON stats.total_returns > 10
WHERE 
    (addr.country IS NULL OR addr.country IN ('USA', 'Canada'))
ORDER BY 
    demo.total_profit DESC, addr.total_return_count DESC
FETCH FIRST 10 ROWS ONLY;
