
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_customer_sk,
        SUM(ws_quantity) AS total_sales_qty,
        SUM(ws_sales_price) AS total_sales_amt,
        ROW_NUMBER() OVER (PARTITION BY ws_customer_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT s.ss_ticket_number) AS store_purchases,
        COUNT(DISTINCT ws.ws_order_number) AS online_purchases
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
LatestSales AS (
    SELECT 
        si.ws_customer_sk,
        SUM(si.total_sales_amt) AS recent_total_amount,
        MAX(si.ws_sold_date_sk) AS last_purchase_date
    FROM 
        SalesCTE si
    WHERE 
        si.rn = 1
    GROUP BY 
        si.ws_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    COALESCE(ls.recent_total_amount, 0) AS recent_total_amount,
    ci.store_purchases,
    ci.online_purchases,
    DENSE_RANK() OVER (ORDER BY COALESCE(ls.recent_total_amount, 0) DESC) AS purchase_rank
FROM 
    CustomerInfo ci
LEFT JOIN 
    LatestSales ls ON ci.c_customer_sk = ls.ws_customer_sk
WHERE 
    (ci.online_purchases > 0 OR ci.store_purchases > 0)
    AND ci.cd_marital_status IS NOT NULL
ORDER BY 
    purchase_rank
LIMIT 100;
