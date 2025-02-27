
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_dep_count > 0 THEN 'Has Dependents'
            ELSE 'No Dependents'
        END AS dependent_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        cm.c_customer_sk,
        cm.cd_gender,
        cm.cd_marital_status,
        cm.cd_purchase_estimate,
        COALESCE(COUNT(DISTINCT ws.ws_order_number), 0) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        CustomerMetrics cm
    LEFT JOIN 
        web_sales ws ON cm.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cm.c_customer_sk, cm.cd_gender, cm.cd_marital_status, cm.cd_purchase_estimate
    HAVING 
        SUM(ws.ws_net_paid) > 10000
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_paid
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_sales <= 10
)
SELECT 
    hi.c_customer_sk,
    hi.cd_gender,
    hi.cd_marital_status,
    hi.total_orders,
    hi.total_spent,
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_paid,
    CASE 
        WHEN hi.cd_gender = 'M' THEN 'Male'
        WHEN hi.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_desc
FROM 
    HighValueCustomers hi
JOIN 
    TopItems ti ON ti.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = hi.c_customer_sk
    )
ORDER BY 
    hi.total_spent DESC, hi.total_orders DESC;
