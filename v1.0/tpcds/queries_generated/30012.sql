
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_item_sk,
        COUNT(*) AS total_sales,
        SUM(ss_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS row_num
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 365
    GROUP BY 
        ss_item_sk
),
TopSales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        S.total_sales,
        S.total_net_paid
    FROM 
        SalesCTE S
    JOIN 
        item i ON S.ss_item_sk = i.i_item_sk
    WHERE 
        S.row_num <= 10
)
SELECT 
    t.web_site_id,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_net_paid_inc_tax) AS total_revenue,
    AVG(ws_net_paid_inc_tax) AS average_order_value,
    COALESCE(CAST(SUM(ws_net_paid_inc_tax) / COUNT(DISTINCT ws_order_number) AS DECIMAL(10, 2)), 0) AS avg_value_per_order
FROM 
    web_sales ws
LEFT JOIN 
    web_site t ON ws.ws_web_site_sk = t.web_site_sk
WHERE 
    ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M'))
    AND EXISTS (
        SELECT 1 
        FROM TopSales ts 
        WHERE ts.i_item_id = ws.ws_item_sk
    )
GROUP BY 
    t.web_site_id
ORDER BY 
    total_revenue DESC
LIMIT 5;
