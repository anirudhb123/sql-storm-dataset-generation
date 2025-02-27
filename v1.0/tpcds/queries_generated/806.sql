
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank,
        MAX(ws_sales_price) AS max_price,
        MAX(ws_ext_sales_price) AS max_ext_price,
        MIN(ws_ext_ship_cost) AS min_ship_cost
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerStores AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_addr_sk,
        s.s_store_sk,
        MAX(s.s_no_of_employees) AS max_employees
    FROM 
        customer c
    LEFT JOIN 
        store s ON c.c_current_addr_sk = s.s_store_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_addr_sk, s.s_store_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_net_paid > 1000
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cnt.c_customer_sk,
    cnt.total_net_paid,
    COALESCE(rs.total_sold, 0) AS total_web_sales,
    COALESCE(cs.max_employees, 0) AS max_store_employees
FROM 
    HighValueCustomers cnt
LEFT JOIN 
    RankedSales rs ON cnt.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    CustomerStores cs ON cnt.c_customer_sk = cs.c_customer_sk
WHERE 
    cnt.total_net_paid > 5000
    AND EXISTS (SELECT 1 
                FROM store_returns sr 
                WHERE sr.sr_customer_sk = cnt.c_customer_sk 
                  AND sr.sr_return_date_sk IS NOT NULL)
ORDER BY 
    total_net_paid DESC, 
    total_web_sales DESC;
