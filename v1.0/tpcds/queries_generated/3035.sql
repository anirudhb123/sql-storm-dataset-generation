
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesStats AS (
    SELECT 
        ws.w_web_site_sk,
        SUM(ws.ws_net_profit) AS profit_sum,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.w_web_site_sk
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_number_employees IS NOT NULL
    GROUP BY 
        s.s_store_sk, s.s_store_name
    HAVING 
        SUM(ss.ss_net_profit) > 10000
)
SELECT 
    cd.c_first_name, 
    cd.c_last_name, 
    cd.c_email_address,
    cs.total_profit,
    cs.sales_count,
    ss.profit_sum,
    ss.order_count
FROM 
    CustomerDetails cd
LEFT JOIN 
    TopStores cs ON cd.c_customer_sk = cs.s_store_sk
JOIN 
    SalesStats ss ON cd.c_customer_sk = ss.w_web_site_sk
WHERE 
    cd.gender_rank = 1
    AND (cd.cd_marital_status IS NOT NULL OR cd.cd_purchase_estimate > 500)
ORDER BY 
    cs.total_profit DESC NULLS LAST;
