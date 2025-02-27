
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.web_site_sk, ws.ws_bill_customer_sk
),
TopPerformers AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_bill_customer_sk,
        rs.total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank <= 3
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_credit_rating,
    tp.total_profit,
    COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
    CASE 
        WHEN SUM(ws.ws_net_profit) IS NULL THEN 'No sales'
        ELSE 'Sales data available' 
    END AS sales_status
FROM 
    TopPerformers tp
JOIN 
    CustomerInfo ci ON tp.ws_bill_customer_sk = ci.c_customer_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = ci.c_customer_sk
GROUP BY 
    ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_credit_rating, tp.total_profit
ORDER BY 
    total_profit DESC;
