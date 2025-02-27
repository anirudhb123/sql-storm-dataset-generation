
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(s.ws_net_profit) AS total_profit,
        1 AS level
    FROM 
        customer c
    JOIN 
        web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk 
    WHERE 
        s.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND s.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name

    UNION ALL

    SELECT
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        SUM(s.ws_net_profit) AS total_profit,
        h.level + 1
    FROM 
        SalesHierarchy h
    JOIN 
        customer ch ON h.c_customer_sk = ch.c_current_cdemo_sk
    LEFT JOIN 
        web_sales s ON ch.c_customer_sk = s.ws_bill_customer_sk
    GROUP BY 
        ch.c_customer_sk, 
        ch.c_first_name, 
        ch.c_last_name, 
        h.level
),
AggregateSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        IFNULL(SUM(ws.ws_net_profit), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_sales_price
    FROM 
        customer c
    LEFT OUTER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
FilteredTopCustomers AS (
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY level ORDER BY total_profit DESC) AS rank,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        totals.total_sales,
        totals.total_orders,
        totals.max_sales_price
    FROM 
        SalesHierarchy h
    JOIN 
        AggregateSales totals ON h.c_customer_sk = totals.c_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    f.total_sales,
    f.total_orders,
    f.max_sales_price,
    COALESCE(h.total_profit, 0) AS hierarchy_profit
FROM 
    FilteredTopCustomers f
LEFT JOIN 
    SalesHierarchy h ON f.c_customer_sk = h.c_customer_sk
WHERE 
    f.rank <= 10
ORDER BY 
    f.total_sales DESC;
