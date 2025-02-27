
WITH SalesCTE AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS total_web_orders,
        AVG(ws_net_profit) AS avg_web_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)  -- last 30 days
    GROUP BY 
        ws_web_site_sk
),
StoreCTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_store_orders,
        AVG(ss_net_profit) AS avg_store_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)  -- last 30 days
    GROUP BY 
        ss_store_sk
),
CombinedSales AS (
    SELECT 
        'Web' AS channel_type,
        s.ws_web_site_sk AS channel_sk,
        s.total_web_sales,
        s.total_web_orders,
        s.avg_web_profit
    FROM 
        SalesCTE s
    UNION ALL
    SELECT 
        'Store' AS channel_type,
        st.ss_store_sk AS channel_sk,
        st.total_store_sales,
        st.total_store_orders,
        st.avg_store_profit
    FROM 
        StoreCTE st
),
FinalSummary AS (
    SELECT 
        channel_type,
        channel_sk,
        total_web_sales,
        total_web_orders,
        total_store_sales,
        total_store_orders,
        GREATEST(total_web_sales, total_store_sales) AS max_sales,
        (total_web_orders + total_store_orders) AS total_orders,
        CASE 
            WHEN total_web_sales IS NULL THEN 0 
            ELSE (total_web_sales / NULLIF(total_web_orders, 0))
        END AS avg_sales_per_order_web,
        CASE 
            WHEN total_store_sales IS NULL THEN 0 
            ELSE (total_store_sales / NULLIF(total_store_orders, 0))
        END AS avg_sales_per_order_store
    FROM (
        SELECT 
            channel_type,
            channel_sk,
            total_web_sales,
            total_web_orders,
            NULL AS total_store_sales,
            NULL AS total_store_orders
        FROM 
            CombinedSales
        WHERE 
            channel_type = 'Web'
        UNION ALL
        SELECT 
            channel_type,
            channel_sk,
            NULL AS total_web_sales,
            NULL AS total_web_orders,
            total_store_sales,
            total_store_orders
        FROM 
            CombinedSales
        WHERE 
            channel_type = 'Store'
    ) AS Combined
)
SELECT 
    channel_type,
    channel_sk,
    COALESCE(total_web_sales, 0) AS total_web_sales,
    COALESCE(total_store_sales, 0) AS total_store_sales,
    total_orders,
    max_sales,
    avg_sales_per_order_web,
    avg_sales_per_order_store
FROM 
    FinalSummary
ORDER BY 
    max_sales DESC;
