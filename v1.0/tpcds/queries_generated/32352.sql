
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY cs.cs_order_number DESC) AS SalesRank
    FROM 
        item i
    JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        sh.i_item_sk,
        sh.i_item_id,
        sh.i_item_desc,
        SUM(sh.cs_sales_price * sh.cs_quantity) AS TotalSales
    FROM 
        SalesHierarchy sh
    WHERE 
        sh.SalesRank <= 3
    GROUP BY 
        sh.i_item_sk,
        sh.i_item_id,
        sh.i_item_desc
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS CustomerProfit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.CustomerProfit,
    COALESCE(ts.TotalSales, 0) AS TotalItemSales,
    (CASE 
        WHEN cs.CustomerProfit > 1000 THEN 'High Value'
        WHEN cs.CustomerProfit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END) AS CustomerValueClassification
FROM 
    CustomerSales cs
LEFT JOIN 
    TopSales ts ON cs.c_customer_sk = (SELECT c.c_customer_sk 
                                        FROM customer c 
                                        ORDER BY RANDOM() LIMIT 1)
ORDER BY 
    cs.CustomerProfit DESC
LIMIT 10;
