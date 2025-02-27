
WITH RECURSIVE RevenueCTE AS (
    SELECT 
        ws.bill_customer_sk, 
        SUM(ws.net_profit) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS revenue_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate IS NOT NULL THEN 
                CASE 
                    WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
                    WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
                    ELSE 'High'
                END
            ELSE 'Unknown'
        END AS purchase_band,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.purchase_band,
        r.total_revenue
    FROM 
        CustomerStats cs
    JOIN 
        RevenueCTE r ON cs.c_customer_sk = r.bill_customer_sk
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    COALESCE(t.purchase_band, 'No Band') AS purchase_band,
    COALESCE(t.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN t.total_revenue > 1000 THEN 'High Value'
        WHEN t.total_revenue > 0 THEN 'Medium Value'
        ELSE 'No Transactions'
    END AS customer_value_category
FROM 
    TopCustomers t
FULL OUTER JOIN 
    store s ON s.s_store_sk IN (SELECT DISTINCT ws.ws_warehouse_sk FROM web_sales ws)
WHERE 
    s.s_country IS NULL OR s.s_country = 'USA'
ORDER BY 
    t.total_revenue DESC, 
    t.c_last_name ASC;
