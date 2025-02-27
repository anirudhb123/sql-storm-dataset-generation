
WITH Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate * 1.1, 0) AS purchase_estimate_adjusted,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
Store_Sales_Info AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
), 
Web_Sales_Info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_quantity,
        AVG(ws.ws_net_profit) AS avg_web_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    WHERE 
        c.c_birth_month = (SELECT MAX(c_birth_month) FROM customer)
    GROUP BY 
        ws.ws_item_sk
), 
Combined_Sales AS (
    SELECT 
        COALESCE(s.ss_item_sk, w.ws_item_sk) AS item_id,
        COALESCE(s.total_quantity_sold, 0) AS store_quantity,
        COALESCE(w.total_web_quantity, 0) AS web_quantity,
        COALESCE(s.total_sales_amount, 0) AS store_sales,
        COALESCE(w.avg_web_profit, 0) AS web_avg_profit
    FROM 
        Store_Sales_Info s
    FULL OUTER JOIN 
        Web_Sales_Info w ON s.ss_item_sk = w.ws_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    cs.item_id,
    cs.store_quantity,
    cs.web_quantity,
    (cs.store_sales + cs.web_avg_profit) AS combined_revenue,
    CASE 
        WHEN cs.store_quantity IS NULL AND cs.web_quantity IS NULL THEN 'No Sales'
        WHEN cs.store_quantity = 0 AND cs.web_quantity = 0 THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    Customer_Info ci
LEFT JOIN 
    Combined_Sales cs ON ci.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer WHERE ci.c_customer_sk = c_customer_sk)
WHERE 
    ci.rank <= 10
ORDER BY 
    combined_revenue DESC NULLS LAST;
