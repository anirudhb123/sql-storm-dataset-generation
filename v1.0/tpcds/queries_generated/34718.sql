
WITH RECURSIVE sales_total AS (
    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
    GROUP BY 
        s_store_sk, ss_sold_date_sk
),
date_range AS (
    SELECT 
        d_date_sk, 
        d_date
    FROM 
        date_dim 
    WHERE 
        d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
profit_by_store AS (
    SELECT 
        s.s_store_name,
        dr.d_date,
        st.total_profit
    FROM 
        sales_total st
    JOIN 
        store s ON st.s_store_sk = s.s_store_sk
    JOIN 
        date_range dr ON st.ss_sold_date_sk = dr.d_date_sk
)
SELECT 
    pbs.s_store_name,
    pbs.d_date,
    COALESCE(pbs.total_profit, 0) AS total_profit,
    RANK() OVER (PARTITION BY pbs.s_store_name ORDER BY pbs.total_profit DESC) AS rank_profit,
    CASE 
        WHEN pbs.total_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    profit_by_store pbs
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT 
            c.c_current_addr_sk 
        FROM 
            customer c 
        WHERE 
            c.c_customer_sk IN (
                SELECT 
                    ss.ss_customer_sk 
                FROM 
                    store_sales ss 
                WHERE 
                    ss.ss_store_sk = (SELECT s_store_sk FROM store WHERE s_store_name = pbs.s_store_name)
            )
        LIMIT 1
    )
ORDER BY 
    pbs.s_store_name, 
    pbs.d_date;
