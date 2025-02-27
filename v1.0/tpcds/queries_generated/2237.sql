
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate
    FROM 
        CustomerInfo ci
    WHERE 
        ci.rk <= 10
),
RecentSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 3
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerSpending AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        COALESCE(rs.total_spent, 0) AS total_spent
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        RecentSales rs ON hvc.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High'
        WHEN cs.total_spent > 500 THEN 'Medium'
        ELSE 'Low'
    END AS spending_category
FROM 
    CustomerSpending cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT OUTER JOIN 
    warehouse w ON w.w_warehouse_sk = (SELECT MAX(inv.inv_warehouse_sk) 
                                         FROM inventory inv 
                                         WHERE inv.inv_item_sk IN (SELECT i.i_item_sk 
                                                                   FROM item i 
                                                                   WHERE i.i_current_price > 50))
WHERE 
    c.c_birth_country IS NULL OR c.c_birth_country <> ''
ORDER BY 
    total_spent DESC, c.c_last_name ASC;
