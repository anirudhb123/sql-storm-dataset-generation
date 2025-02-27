
WITH RankedSales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rnk
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(ss2.ss_sold_date_sk) FROM store_sales ss2) 
    GROUP BY 
        s.s_store_id
),
TopStores AS (
    SELECT 
        store_id, 
        total_sales 
    FROM 
        RankedSales 
    WHERE 
        rnk <= 5
),
CustomerReturns AS (
    SELECT 
        sr.rs_store_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.rs_store_sk
)

SELECT 
    t.store_id,
    t.total_sales,
    COALESCE(c.total_returns, 0) AS total_returns,
    COALESCE(c.total_return_amount, 0) AS total_return_amount,
    (t.total_sales - COALESCE(c.total_return_amount, 0)) AS net_sales
FROM 
    TopStores t
LEFT JOIN 
    CustomerReturns c ON t.store_id = c.rs_store_sk
ORDER BY 
    net_sales DESC;
