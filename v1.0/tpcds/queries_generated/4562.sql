
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_paid DESC) AS rn,
        SUM(ws_net_paid) OVER (PARTITION BY ws_bill_customer_sk) AS total_spent,
        COUNT(ws_order_number) OVER (PARTITION BY ws_bill_customer_sk) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458838 AND 2458838 + 30  -- Example date range
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating, 
        COALESCE(SUM(ws.net_profit), 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    cs.total_spent,
    cs.order_count,
    (SELECT COUNT(DISTINCT wr_order_number) 
        FROM web_returns wr 
        WHERE wr_returning_customer_sk = ci.c_customer_sk) AS return_count
FROM 
    CustomerInfo ci
JOIN 
    RankedSales cs ON ci.c_customer_sk = cs.ws_bill_customer_sk AND cs.rn = 1
WHERE 
    total_profit > 5000 AND cd_gender = 'F' 
ORDER BY 
    total_spent DESC
LIMIT 10;
