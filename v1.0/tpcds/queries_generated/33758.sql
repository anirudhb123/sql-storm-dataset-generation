
WITH RECURSIVE SalesSummary AS (
    SELECT 
        ss.sold_date_sk,
        ss.store_sk,
        SUM(ss.net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.customer_sk) AS unique_customers,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss.net_profit) DESC) AS rank
    FROM 
        store_sales ss
    GROUP BY 
        ss.sold_date_sk, ss.store_sk
),
TopStores AS (
    SELECT 
        store_sk,
        total_net_profit,
        unique_customers,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS store_rank
    FROM 
        SalesSummary
)

SELECT 
    st.store_id,
    st.store_name,
    ts.total_net_profit,
    COALESCE(ts.unique_customers, 0) AS unique_customers,
    dc.d_year,
    dc.d_month_seq,
    dc.d_week_seq
FROM 
    TopStores ts
LEFT JOIN 
    store st ON ts.store_sk = st.s_store_sk
LEFT JOIN 
    date_dim dc ON dc.d_date_sk = ts.sold_date_sk
WHERE 
    ts.store_rank <= 10
    AND (dc.d_month_seq IS NOT NULL OR dc.d_year = 2023)
ORDER BY 
    ts.total_net_profit DESC;

WITH InventorySummary AS (
    SELECT 
        inv.warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.warehouse_sk
)

SELECT 
    ws.warehouse_id,
    ws.warehouse_name,
    ISNULL(is.total_quantity, 0) AS total_quantity_in_stock
FROM 
    warehouse ws
LEFT JOIN 
    InventorySummary is ON ws.w_warehouse_sk = is.warehouse_sk
ORDER BY 
    total_quantity_in_stock DESC;
