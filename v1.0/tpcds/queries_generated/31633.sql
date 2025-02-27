
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        1 AS sales_level
    FROM 
        web_sales
    WHERE 
        ws_sales_price > (
            SELECT 
                AVG(ws_sales_price) 
            FROM 
                web_sales
        )
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cte.sales_level + 1
    FROM 
        Sales_CTE cte
    JOIN 
        catalog_sales cs ON cte.ws_item_sk = cs.cs_item_sk
    WHERE 
        cs_sales_price < cte.ws_sales_price * 0.9
),

Address_Summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),

Order_Summary AS (
    SELECT 
        ss_store_sk,
        COUNT(ss_ticket_number) AS order_count,
        SUM(ss_net_paid) AS total_revenue
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)

SELECT 
    s.ws_item_sk,
    s.ws_order_number,
    COALESCE(a.address_count, 0) AS address_count,
    o.order_count,
    o.total_revenue,
    ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY s.ws_order_number DESC) AS rank
FROM 
    Sales_CTE s
LEFT JOIN 
    Address_Summary a ON a.ca_state = (
        SELECT 
            ca_state 
        FROM 
            customer_address 
        WHERE 
            ca_address_sk = (
                SELECT 
                    c_current_addr_sk 
                FROM 
                    customer 
                WHERE 
                    c_customer_sk = s.ws_order_number
            )
    )
JOIN 
    Order_Summary o ON o.ss_store_sk = s.ws_order_number
WHERE 
    s.sales_level <= 5
ORDER BY 
    s.ws_item_sk, rank;
