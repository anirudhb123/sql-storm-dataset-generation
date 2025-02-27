
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        1 AS level
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    UNION ALL
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) + sh.total_sales,
        sh.level + 1
    FROM 
        SalesHierarchy sh
    JOIN 
        customer c ON c.c_customer_sk = sh.ws_bill_customer_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        sh.level < 10
    GROUP BY 
        c.c_customer_sk, sh.total_sales
),
RankedSales AS (
    SELECT 
        sh.ws_bill_customer_sk,
        sh.total_sales,
        RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        SalesHierarchy sh
),
AverageApple AS (
    SELECT 
        AVG(ss.ss_net_profit) AS average_net_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_item_sk IN (
            SELECT i.i_item_sk FROM item i WHERE i.i_product_name LIKE '%apple%'
        )
)
SELECT 
    r.ws_bill_customer_sk,
    r.total_sales,
    r.sales_rank,
    a.average_net_profit,
    CASE 
        WHEN r.total_sales > a.average_net_profit THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison,
    CASE 
        WHEN r.sales_rank < 5 THEN TRUE
        ELSE FALSE
    END AS top_five_customer
FROM 
    RankedSales r
CROSS JOIN 
    AverageApple a
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = r.ws_bill_customer_sk
    )
WHERE 
    r.total_sales IS NOT NULL
ORDER BY 
    r.total_sales DESC;
