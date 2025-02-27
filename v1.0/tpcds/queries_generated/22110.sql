
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id,
        SUM(is.total_sales) AS sum_sales,
        SUM(is.total_profit) AS sum_profit
    FROM 
        CustomerStats cs
    JOIN 
        ItemSales is ON cs.c_current_cdemo_sk = is.ws_item_sk
    WHERE 
        cs.purchase_rank <= 5
    GROUP BY 
        cs.c_customer_id
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.dep_count,
    COALESCE(hv.sum_sales, 0) AS total_sales,
    COALESCE(hv.sum_profit, 0) AS total_profit,
    CASE 
        WHEN hv.sum_sales IS NULL THEN 'No purchases'
        ELSE 'Purchases made'
    END AS purchase_status
FROM 
    customer c
JOIN 
    CustomerStats cs ON c.c_current_cdemo_sk = cs.c_current_cdemo_sk
LEFT JOIN 
    HighValueCustomers hv ON c.c_customer_id = hv.c_customer_id
WHERE 
    (cs.dep_count > 2 OR cs.cd_gender = 'M') AND
    (cs.cd_purchase_estimate > 1000 OR COALESCE(hv.sum_sales, 0) > 5000)
ORDER BY 
    total_sales DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
