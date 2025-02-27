
WITH RECURSIVE StoreProfit AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk

    UNION ALL

    SELECT 
        s.s_store_sk,
        MAX(sp.total_net_profit) + COALESCE(SUM(ws.ws_net_profit), 0),
        level + 1
    FROM 
        store s
    LEFT JOIN 
        StoreProfit sp ON s.s_store_sk = sp.ss_store_sk
    LEFT JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    WHERE 
        level < 5
    GROUP BY 
        s.s_store_sk, sp.total_net_profit
), CustomerDemographics AS (
    SELECT 
        cd cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd_gender, cd_marital_status
), RelevantReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_returned_date_sk, sr_return_time_sk
)
SELECT 
    d.d_date,
    COALESCE(sp.total_net_profit, 0) AS total_profit,
    SUM(cr.total_return_amt) AS total_returns,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN cd.customer_count ELSE 0 END) AS married_customers,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers
FROM 
    date_dim d
LEFT JOIN 
    StoreProfit sp ON d.d_date_sk = DAYOFYEAR(CURRENT_DATE) + sp.ss_store_sk
LEFT JOIN 
    RelevantReturns cr ON d.d_date_sk = cr.sr_returned_date_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN 
    customer c ON c.c_current_addr_sk = cr.sr_addr_sk
WHERE 
    d.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 
    d.d_date, sp.total_net_profit
ORDER BY 
    d.d_date;
