
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 10
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, ca.ca_city, ca.ca_state
),
SalesSummary AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        SUM(a.order_count) AS total_orders,
        SUM(CASE WHEN a.order_count > 0 THEN 1 ELSE 0 END) AS active_customers
    FROM 
        CustomerAddresses a
    GROUP BY 
        a.ca_city, a.ca_state
)
SELECT 
    s.ca_city,
    s.ca_state,
    s.total_orders,
    s.active_customers,
    COALESCE(t.total_quantity, 0) AS top_item_quantity,
    COALESCE(t.total_sales, 0) AS top_item_sales
FROM 
    SalesSummary s
LEFT JOIN 
    (SELECT 
        ca.ca_city,
        ca.ca_state,
        SUM(t.total_quantity) AS total_quantity,
        SUM(t.total_sales) AS total_sales
    FROM 
        TopItems t
    JOIN 
        CustomerAddresses ca ON t.ws_item_sk IN (
            SELECT ws_item_sk FROM web_sales WHERE ws_order_number IN (
                SELECT ws_order_number FROM web_sales WHERE ws_bill_customer_sk IN (
                    SELECT c_customer_sk FROM customer
                    WHERE c_current_addr_sk IS NOT NULL
                )
            )
        )
    GROUP BY 
        ca.ca_city, ca.ca_state) t ON s.ca_city = t.ca_city AND s.ca_state = t.ca_state
WHERE 
    s.total_orders > 0
ORDER BY 
    s.total_orders DESC, s.ca_city;
