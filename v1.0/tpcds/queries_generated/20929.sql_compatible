
WITH RankedSales AS (
    SELECT 
        ss.s_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss.s_store_sk ORDER BY ss.ss_net_paid DESC) AS rank
    FROM 
        store_sales ss
    WHERE
        ss.ss_sold_date_sk BETWEEN (
            SELECT MIN(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_moy = 12
        ) AND (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_moy = 12
        )
), 
SalesReturns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns 
    GROUP BY 
        sr_store_sk
), 
HighGrossingStores AS (
    SELECT 
        rs.s_store_sk, 
        SUM(rs.ss_net_paid) AS total_sales_net
    FROM 
        RankedSales rs
    GROUP BY 
        rs.s_store_sk
    HAVING 
        SUM(rs.ss_net_paid) > (
            SELECT AVG(total_sales_net) 
            FROM (
                SELECT 
                    s_store_sk, 
                    SUM(ss_net_paid) AS total_sales_net 
                FROM 
                    store_sales 
                GROUP BY 
                    s_store_sk
            ) avg_sales
        )
)
SELECT 
    w.w_warehouse_name,
    hs.total_sales_net,
    COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
    (SELECT COUNT(DISTINCT c.c_customer_sk) 
     FROM customer c 
     WHERE c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_city = 'Los Angeles') 
     AND c.c_first_shipto_date_sk > 0) AS customer_count,
    CASE 
        WHEN hs.total_sales_net > 10000 THEN 'High Performer'
        ELSE 'Standard Performer'
    END AS performance_category
FROM 
    HighGrossingStores hs
JOIN 
    warehouse w ON hs.s_store_sk = w.w_warehouse_sk
LEFT JOIN 
    SalesReturns rs ON hs.s_store_sk = rs.sr_store_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM web_sales ws 
        WHERE ws.ws_item_sk IN (SELECT DISTINCT i_item_sk FROM item WHERE i_brand = 'BrandA') 
        AND ws.ws_ship_date_sk BETWEEN (SELECT MIN(ss.ss_sold_date_sk) FROM store_sales ss) 
                                    AND (SELECT MAX(ss.ss_sold_date_sk) FROM store_sales ss)
    )
ORDER BY 
    hs.total_sales_net DESC, 
    total_returned_quantity ASC
LIMIT 10;
