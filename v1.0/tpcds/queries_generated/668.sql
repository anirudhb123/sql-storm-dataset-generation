
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_by_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_web_site_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
    HAVING 
        SUM(ws_sales_price) > 1000
),
StoreAndCustomerReturns AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_refunds
    FROM 
        store_sales ss
    LEFT JOIN 
        store_returns sr ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    w.w_warehouse_name,
    s.s_store_name,
    cu.c_first_name,
    cu.c_last_name,
    COALESCE(total_returns, 0) AS returns,
    COALESCE(total_refunds, 0) AS refunds,
    (ws.total_sales / NULLIF(total_sales, 0)) AS sales_ratio,
    CASE 
        WHEN CHAR_LENGTH(cu.c_first_name) > 5 THEN 'Long Name' 
        ELSE 'Short Name' 
    END AS name_length_category
FROM 
    Warehouse w
LEFT JOIN 
    Store s ON w.w_warehouse_sk = s.s_store_sk
LEFT JOIN 
    HighValueCustomers cu ON s.s_store_sk = cu.c_customer_sk
LEFT JOIN 
    StoreAndCustomerReturns scr ON s.s_store_sk = scr.ss_store_sk
LEFT JOIN 
    (SELECT ws_item_sk, SUM(ws_ext_sales_price) AS total_sales FROM web_sales GROUP BY ws_item_sk) AS ws 
    ON cu.c_customer_sk = ws.ws_item_sk
WHERE 
    w.w_country = 'USA' 
    AND cu.c_birth_country IS NOT NULL
ORDER BY 
    total_returns DESC, total_refunds DESC
LIMIT 100;
