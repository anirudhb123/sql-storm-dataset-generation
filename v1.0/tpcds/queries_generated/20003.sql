
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price BETWEEN 10 AND 100
),
TopSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price * ws_quantity) AS total_spent,
        COUNT(ws_item_sk) AS total_items
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
    GROUP BY 
        ws_bill_customer_sk
),
Customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        td.total_spent,
        td.total_items
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TopSales td ON c.c_customer_sk = td.ws_bill_customer_sk
    LEFT JOIN 
        (SELECT 
            d_year,
            COUNT(DISTINCT c_customer_sk) AS count_customers
         FROM 
            customer
         GROUP BY 
            d_year) AS yearly_count ON yearly_count.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
)
SELECT 
    COALESCE(c.c_first_name, 'Unknown') AS first_name,
    COALESCE(c.c_last_name, 'Unknown') AS last_name,
    c.c_customer_id,
    COALESCE(td.total_spent, 0) AS total_spent,
    COALESCE(td.total_items, 0) AS total_items,
    COALESCE(yc.count_customers, 0) AS total_customers_in_year
FROM 
    Customers c
FULL OUTER JOIN 
    (SELECT 
        d_year,
        COUNT(DISTINCT c_customer_sk) AS count_customers
     FROM 
        customer
     GROUP BY 
        d_year
    ) AS yc ON yc.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE 
    (yc.count_customers IS NULL OR td.total_spent IS NOT NULL)
ORDER BY 
    td.total_spent DESC NULLS LAST;
