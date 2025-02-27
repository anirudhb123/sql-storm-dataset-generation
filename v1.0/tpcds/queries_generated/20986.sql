
WITH RECURSIVE SalesRanks AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT 
        s.c_first_name,
        s.c_last_name,
        s.ws_order_number,
        s.ws_sales_price
    FROM 
        SalesRanks s
    WHERE 
        s.sales_rank <= 3
),
AggregateResults AS (
    SELECT 
        t.c_first_name,
        t.c_last_name,
        SUM(t.ws_sales_price) AS total_sales,
        COUNT(t.ws_order_number) AS order_count
    FROM 
        TopSales t
    GROUP BY 
        t.c_first_name, t.c_last_name
)
SELECT 
    ar.c_first_name,
    ar.c_last_name,
    ar.total_sales,
    ar.order_count,
    CASE
        WHEN ar.total_sales > 1000 THEN 'High Roller'
        WHEN ar.total_sales BETWEEN 500 AND 1000 THEN 'Regular'
        ELSE 'Low Spender'
    END AS customer_category,
    (SELECT 
         COUNT(*) FROM customer_address ca 
     WHERE 
         ca.ca_state IN (SELECT DISTINCT c.ca_state FROM customer_address c 
                         WHERE c.ca_address_sk IS NOT NULL 
                         AND c.ca_city IS NOT NULL)
         AND ca.ca_country = 'USA') AS total_addresses,
    COALESCE((
        SELECT 
            SUM(ws.ws_net_profit) 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_bill_customer_sk = ar.c_first_name || ar.c_last_name
    ), 0) AS net_profit
FROM 
    AggregateResults ar
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = ar.c_first_name || ar.c_last_name
WHERE 
    (ar.total_sales > 0 OR ar.order_count IS NOT NULL)
ORDER BY 
    ar.total_sales DESC
LIMIT 10;
