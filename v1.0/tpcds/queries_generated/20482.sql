
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        s_store_sk, ss_item_sk
),
TopStores AS (
    SELECT 
        s_city,
        s_state,
        COUNT(DISTINCT s_store_sk) AS store_count
    FROM 
        store
    GROUP BY 
        s_city, s_state
    HAVING 
        COUNT(DISTINCT s_store_sk) > 1
),
CustomerReturns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim)
    GROUP BY 
        sr_store_sk
)
SELECT 
    a.s_store_id,
    a.s_city,
    a.s_state,
    COALESCE(b.total_quantity, 0) AS sold_quantity,
    COALESCE(b.total_net_paid, 0) AS net_paid,
    COALESCE(c.total_returned_quantity, 0) AS returned_quantity,
    d.store_count,
    CASE 
        WHEN COALESCE(c.return_count, 0) > 0 THEN 'High Return'
        ELSE 'Low Return'
    END AS return_analysis
FROM 
    store a
LEFT JOIN 
    RankedSales b ON a.s_store_sk = b.s_store_sk AND b.sales_rank = 1
LEFT JOIN 
    CustomerReturns c ON a.s_store_sk = c.s_store_sk
JOIN 
    TopStores d ON a.s_city = d.s_city AND a.s_state = d.s_state
WHERE 
    a.s_closed_date_sk IS NULL 
    AND (d.store_count > 0 OR a.s_country = 'USA') 
ORDER BY 
    a.s_city, net_paid DESC;
