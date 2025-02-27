
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, ss_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        (SELECT COUNT(DISTINCT sr_item_sk) 
         FROM store_returns 
         WHERE sr_customer_sk = c.c_customer_sk) AS returns_count,
        (SELECT COUNT(DISTINCT ws_item_sk) 
         FROM web_sales 
         WHERE ws_bill_customer_sk = c.c_customer_sk) AS web_sales_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        (c.c_birth_month IS NULL OR c.c_birth_month BETWEEN 1 AND 6) 
        AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
),
TopStores AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        COUNT(DISTINCT ss_ticket_number) AS total_tickets,
        COUNT(DISTINCT ws_order_number) AS total_web_orders
    FROM 
        warehouse w
    LEFT JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id, w.w_warehouse_name, w.w_city
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_marital_status,
    cs.cd_gender,
    ts.w_warehouse_name,
    ts.total_tickets,
    ts.total_web_orders,
    rs.total_sales
FROM 
    CustomerStats cs
LEFT JOIN 
    TopStores ts ON (ts.total_tickets > 10 OR ts.total_web_orders > 5)
LEFT JOIN 
    RankedSales rs ON (rs.sales_rank = 1 AND rs.ss_store_sk IN (SELECT s_store_sk FROM store WHERE s_closed_date_sk IS NULL))
WHERE 
    (cs.returns_count > 0 OR cs.web_sales_count > 0)
    AND NOT EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_customer_sk = cs.c_customer_sk AND sr.sr_return_quantity IS NULL)
ORDER BY 
    cs.c_last_name, cs.c_first_name;
