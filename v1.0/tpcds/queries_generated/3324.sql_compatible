
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20201201 AND 20201231
),
CustomerReturns AS (
    SELECT 
        cr.cr_returning_customer_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk IN (SELECT d.d_date_sk 
                                    FROM date_dim d 
                                    WHERE d.d_date BETWEEN '2020-12-01' AND '2020-12-31')
    GROUP BY 
        cr.cr_returning_customer_sk
),
StorePerformance AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_list_price) AS avg_list_price,
        CUME_DIST() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS net_profit_rank
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN 20201201 AND 20201231
    GROUP BY 
        ss.s_store_sk
)
SELECT 
    ca.ca_address_id,
    c.c_customer_id,
    SUM(COALESCE(rs.ws_quantity, 0)) AS total_quantity_sold,
    COALESCE(cr.total_returned_quantity, 0) AS total_returns,
    sp.total_net_profit,
    sp.avg_list_price,
    CASE 
        WHEN sp.net_profit_rank <= 0.2 THEN 'Top Performer'
        ELSE 'Average Performer'
    END AS performance_category
FROM 
    customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN RankedSales rs ON c.c_customer_sk = rs.ws_order_number
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN StorePerformance sp ON ca.ca_address_sk = sp.s_store_sk
WHERE 
    c.c_birth_year <= 1990
GROUP BY 
    ca.ca_address_id, c.c_customer_id, cr.total_returned_quantity, sp.total_net_profit, sp.avg_list_price, sp.net_profit_rank
HAVING 
    SUM(COALESCE(rs.ws_quantity, 0)) > 10
ORDER BY 
    total_quantity_sold DESC;
