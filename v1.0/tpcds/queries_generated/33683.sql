
WITH RECURSIVE SalesTrends AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_quantity) AS total_sales,
        SUM(ss.ss_net_profit) AS net_profit
    FROM 
        store s
    JOIN
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, d.d_year

    UNION ALL

    SELECT 
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_quantity) + (SELECT COALESCE(SUM(ws.ws_quantity), 0) FROM web_sales ws WHERE ws.ws_ship_date_sk = d.d_date_sk AND ws.ws_bill_customer_sk = s.s_store_sk) AS total_sales,
        SUM(ss.ss_net_profit) + (SELECT COALESCE(SUM(ws.ws_net_profit), 0) FROM web_sales ws WHERE ws.ws_ship_date_sk = d.d_date_sk AND ws.ws_bill_customer_sk = s.s_store_sk) AS net_profit
    FROM 
        store s
    JOIN 
        SalesTrends st ON st.s_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON d.d_year = st.d_year + 1
    GROUP BY 
        s.s_store_sk, s.s_store_name, d.d_year
),
RecentSales AS (
    SELECT 
        r.reason_id,
        r.r_reason_desc,
        SUM(cs.cs_net_profit) AS total_refunds
    FROM 
        catalog_returns cr
    JOIN 
        reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN 
        catalog_sales cs ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
    WHERE 
        cr.cr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        r.reason_id, r.r_reason_desc
),
FinalSales AS (
    SELECT 
        st.s_store_name,
        st.d_year,
        st.total_sales,
        st.net_profit,
        COALESCE(re.total_refunds, 0) AS total_refunds
    FROM 
        SalesTrends st
    LEFT JOIN 
        RecentSales re ON st.s_store_sk = re.reason_id
)

SELECT 
    fs.s_store_name,
    fs.d_year,
    fs.total_sales,
    fs.net_profit,
    CASE 
        WHEN fs.total_refunds IS NOT NULL THEN 
            fs.total_sales - fs.total_refunds 
        ELSE 
            fs.total_sales 
    END AS adjusted_sales
FROM 
    FinalSales fs
WHERE 
    fs.net_profit > (
        SELECT AVG(net_profit) FROM FinalSales
    )
ORDER BY 
    fs.net_profit DESC;
