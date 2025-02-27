
WITH RankedSales AS (
    SELECT 
        cs.ss_sold_date_sk,
        cs.ss_store_sk,
        SUM(cs.ss_quantity) AS total_quantity,
        SUM(cs.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.ss_store_sk ORDER BY SUM(cs.ss_net_paid) DESC) AS rank
    FROM 
        store_sales cs
    INNER JOIN 
        date_dim dd ON cs.ss_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month IN (6, 7)
    GROUP BY 
        cs.ss_sold_date_sk, cs.ss_store_sk
),
TopStores AS (
    SELECT
        rs.ss_store_sk,
        rs.total_quantity,
        rs.total_sales,
        st.s_store_name,
        RANK() OVER (ORDER BY rs.total_sales DESC) AS store_rank
    FROM 
        RankedSales rs
    INNER JOIN 
        store st ON rs.ss_store_sk = st.s_store_sk
    WHERE 
        rs.rank = 1
)
SELECT 
    ts.store_rank,
    ts.s_store_name,
    ts.total_quantity,
    ts.total_sales
FROM 
    TopStores ts
WHERE 
    ts.store_rank <= 10
ORDER BY 
    ts.store_rank;
