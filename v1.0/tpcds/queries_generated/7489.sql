
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.web_site_sk) AS total_websites,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, cd.cd_purchase_estimate
),
monthly_performance AS (
    SELECT 
        date_dim.d_year,
        date_dim.d_month_seq,
        SUM(ss.total_quantity) AS monthly_quantity,
        SUM(ss.total_sales) AS monthly_sales,
        SUM(ss.total_profit) AS monthly_profit
    FROM 
        sales_summary ss
    JOIN 
        date_dim ON ss.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY 
        date_dim.d_year, date_dim.d_month_seq
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_credit_rating,
    cs.cd_purchase_estimate,
    mp.d_year,
    mp.d_month_seq,
    mp.monthly_quantity,
    mp.monthly_sales,
    mp.monthly_profit
FROM 
    customer_summary cs
JOIN 
    monthly_performance mp ON cs.c_customer_sk IN (
        SELECT c.c_customer_sk
        FROM customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        WHERE ws.ws_sold_date_sk IN (
            SELECT ws_sold_date_sk
            FROM store_sales
            GROUP BY ws_sold_date_sk
            HAVING SUM(ss_net_profit) > 1000
        )
    )
ORDER BY 
    cs.c_customer_sk, mp.d_year, mp.d_month_seq;
