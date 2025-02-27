
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.web_site_sk) AS total_profit
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
HighValueCustomers AS (
    SELECT 
        customer_stats.c_customer_sk,
        customer_stats.order_count,
        customer_stats.total_spent,
        da.d_average_daily_sales,
        CASE
            WHEN da.d_average_daily_sales > 1000 THEN 'High Value'
            WHEN da.d_average_daily_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        CustomerStats AS customer_stats
    JOIN (
        SELECT 
            AVG(ws.ws_net_profit) AS d_average_daily_sales
        FROM 
            web_sales AS ws
        JOIN 
            date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
        WHERE 
            dd.d_year = 2023
        GROUP BY 
            dd.d_date
    ) AS da ON customer_stats.total_spent > da.d_average_daily_sales
)
SELECT 
    hvc.c_customer_sk,
    hvc.order_count,
    hvc.total_spent,
    hvc.customer_value,
    rs.ws_sales_price AS top_sales_price,
    rs.total_profit
FROM 
    HighValueCustomers AS hvc
LEFT JOIN 
    RankedSales AS rs ON hvc.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales)
WHERE 
    hvc.customer_value = 'High Value' OR hvc.customer_value = 'Medium Value'
ORDER BY 
    hvc.total_spent DESC, hvc.order_count DESC;
