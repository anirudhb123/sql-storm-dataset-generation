
WITH RankedSales AS (
    SELECT 
        w.warehouse_id,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    GROUP BY 
        w.warehouse_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    r.warehouse_id,
    hv.c_customer_id,
    hv.c_first_name,
    hv.c_last_name,
    hv.cd_gender,
    r.total_sales,
    r.sales_rank,
    hv.total_spent,
    COALESCE(rt.total_returns, 0) AS total_returns,
    COALESCE(rt.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN hv.total_spent > 2000 THEN 'High Value'
        ELSE 'Regular Value'
    END AS customer_value_category
FROM 
    RankedSales r
LEFT JOIN 
    HighValueCustomers hv ON r.warehouse_id = hv.c_customer_id
LEFT JOIN 
    ReturnStats rt ON rt.sr_item_sk IN (
        SELECT DISTINCT ws_item_sk
        FROM web_sales
        WHERE ws_bill_customer_sk = hv.c_customer_id
    )
WHERE 
    r.sales_rank = 1
ORDER BY 
    r.total_sales DESC, hv.total_spent DESC;
