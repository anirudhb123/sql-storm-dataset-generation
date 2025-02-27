
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_net_paid_inc_tax,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid_inc_tax DESC) as sales_rank,
        COALESCE(ws.ws_ext_discount_amt, 0) as effective_discount,
        CASE 
            WHEN ws.ws_net_paid_inc_tax < 0 THEN 'Refunded'
            ELSE 'Paid'
        END as transaction_status
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TotalSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_paid_inc_tax) AS total_net_paid,
        COUNT(*) AS transaction_count,
        MAX(rs.effective_discount) AS max_discount
    FROM 
        RankedSales rs
    WHERE 
        rs.transaction_status = 'Paid' 
        AND rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        COALESCE(COUNT(c.c_customer_sk), 0) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_zip
),
AggregateSales AS (
    SELECT 
        ti.ws_item_sk, 
        ti.total_net_paid, 
        ai.ca_city, 
        ai.ca_state,
        ai.customer_count
    FROM 
        TotalSales ti
    JOIN 
        web_page wp ON wp.wp_web_page_sk = (SELECT wp2.wp_web_page_sk 
                                             FROM web_sales ws2 
                                             JOIN web_page wp2 ON ws2.ws_web_page_sk = wp2.wp_web_page_sk 
                                             WHERE ws2.ws_item_sk = ti.ws_item_sk
                                             LIMIT 1)
    JOIN 
        AddressInfo ai ON ai.customer_count > 0
)
SELECT 
    asales.ws_item_sk,
    asales.total_net_paid,
    ai.ca_city, 
    ai.ca_state,
    CASE 
        WHEN ai.customer_count IS NULL THEN 'No Customers'
        ELSE 'Customers Present'
    END AS customer_status,
    ROUND(asales.total_net_paid / NULLIF(asales.customer_count, 0), 2) AS avg_spend_per_customer
FROM 
    AggregateSales asales
LEFT JOIN 
    AddressInfo ai ON asales.ca_city = ai.ca_city AND asales.ca_state = ai.ca_state
ORDER BY 
    asales.total_net_paid DESC, 
    ai.ca_city ASC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
