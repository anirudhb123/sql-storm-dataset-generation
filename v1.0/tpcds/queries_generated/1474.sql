
WITH SalesCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopSales AS (
    SELECT 
        *, 
        CASE 
            WHEN total_sales IS NULL THEN 'No Sales'
            ELSE CONCAT('Total Sales: $', ROUND(total_sales, 2))
        END AS sales_message
    FROM 
        SalesCTE
    WHERE 
        rn = 1
)

SELECT 
    t.c_customer_sk, 
    t.c_first_name, 
    t.c_last_name, 
    t.total_sales, 
    t.order_count, 
    t.sales_message,
    COALESCE(NULLIF(t.total_sales, 0), 'Zero Sales') AS adjusted_sales,
    EXISTS (
        SELECT 1 
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = t.c_customer_sk)
          AND cd.cd_marital_status = 'M'
    ) AS is_married
FROM 
    TopSales t
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = t.c_customer_sk)
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    t.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
