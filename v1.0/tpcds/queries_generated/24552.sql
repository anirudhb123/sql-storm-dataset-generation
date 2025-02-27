
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_quantity) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk
),
TopStores AS (
    SELECT 
        w.w_warehouse_id,
        c.c_first_name,
        c.c_last_name,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        RANK() OVER (ORDER BY SUM(rs.total_quantity) DESC) AS rank_id
    FROM 
        RankedSales rs
        JOIN store s ON rs.ss_store_sk = s.s_store_sk
        JOIN warehouse w ON s.s_company_id = w.w_warehouse_sk
        JOIN customer c ON c.c_customer_sk = (SELECT top 1 c1.c_customer_sk 
                                               FROM customer c1 
                                               WHERE c1.c_current_addr_sk = c.c_current_addr_sk 
                                               ORDER BY c1.c_birth_year DESC)
        JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE 
        a.ca_state IN ('CA', 'NY', 'TX')
    GROUP BY 
        w.w_warehouse_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, a.ca_country
    HAVING 
        COUNT(DISTINCT c.c_customer_id) > 0
)
SELECT 
    ts.w_warehouse_id,
    ts.c_first_name,
    ts.c_last_name,
    ts.ca_city,
    ts.ca_state,
    ts.ca_country,
    CASE 
        WHEN ts.rank_id IS NULL THEN 'Not Ranked'
        ELSE CAST(ts.rank_id AS VARCHAR)
    END AS sales_rank
FROM 
    TopStores ts
FULL OUTER JOIN store s ON ts.w_warehouse_id = s.s_store_id
WHERE 
    (s.s_open_date IS NULL AND s.s_closed_date_sk IS NOT NULL) OR 
    (s.s_closed_date_sk IS NULL AND ts.ca_country IS NOT NULL)
ORDER BY 
    ts.ca_city DESC, 
    ts.ca_country ASC NULLS LAST;
