
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    LEFT JOIN 
        catalog_sales AS cs ON ws.ws_order_number = cs.cs_order_number
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6)
    GROUP BY 
        ws.web_site_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cnt.hd_income_band_sk,
        SharedWebSales = CASE 
                            WHEN ws.web_site_sk IS NOT NULL THEN 1 
                            ELSE 0 
                        END
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS cnt ON c.c_current_cdemo_sk = cnt.hd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    SUM(ss.total_net_profit) AS total_profit,
    AVG(ss.total_orders) AS avg_orders,
    COUNT(DISTINCT CASE WHEN cd.SharedWebSales = 1 THEN cd.c_customer_sk END) AS web_shoppers,
    COALESCE(MAX(ss.profit_rank), 0) AS highest_profit_rank
FROM 
    customer_details AS cd
LEFT JOIN 
    sales_summary AS ss ON cd.c_current_cdemo_sk = ss.web_site_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_profit DESC, customer_count DESC;
