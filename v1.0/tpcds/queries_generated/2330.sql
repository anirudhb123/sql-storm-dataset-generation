
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c_customer_sk
    HAVING 
        SUM(ws_net_paid) > 5000
),
StoreReturnsSummary AS (
    SELECT 
        sr_store_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_value,
        AVG(sr_return_qty) AS avg_return_qty
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    s.s_store_sk,
    s.s_store_name,
    ss.total_returns,
    ss.total_return_value,
    ss.avg_return_qty,
    COALESCE(hvc.total_spent, 0) AS high_value_customer_spent,
    COALESCE(rk.ws_item_sk, -1) AS top_item_sk
FROM 
    store s
LEFT JOIN 
    StoreReturnsSummary ss ON s.s_store_sk = ss.s_store_sk
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_net_paid > 1000) 
LEFT JOIN 
    RankedSales rk ON rk.ws_item_sk = ANY(SELECT i_item_sk FROM item WHERE i_current_price > 50)
WHERE 
    s.s_state = 'CA' 
    AND s.s_number_employees IS NOT NULL
ORDER BY 
    total_return_value DESC, 
    total_returns DESC;
