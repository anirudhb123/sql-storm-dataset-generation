
WITH RankedSales AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(CASE 
                WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_sales_price * ws.ws_quantity 
                ELSE 0 
            END) AS total_web_sales,
        SUM(CASE 
                WHEN cs.cs_ship_date_sk IS NOT NULL THEN cs.cs_sales_price * cs.cs_quantity 
                ELSE 0 
            END) AS total_catalog_sales,
        SUM(CASE 
                WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_sales_price * ss.ss_quantity 
                ELSE 0 
            END) AS total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, c.c_gender ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM 
        date_dim d
    LEFT JOIN
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    JOIN 
        customer c ON c.c_customer_sk IN (ws.ws_bill_customer_sk, cs.cs_bill_customer_sk, ss.ss_customer_sk)
    WHERE
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        d.d_year, c.c_gender
)
SELECT
    year,
    gender,
    total_web_sales,
    total_catalog_sales,
    total_store_sales
FROM 
    RankedSales
WHERE 
    rank <= 10
ORDER BY 
    year, gender, total_web_sales DESC;
