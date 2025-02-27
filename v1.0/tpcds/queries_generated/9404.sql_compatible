
WITH SalesData AS (
    SELECT 
        WS.ws_sold_date_sk, 
        WS.ws_item_sk, 
        WS.ws_sales_price, 
        WS.ws_quantity,
        C.c_gender,
        C.c_birth_year,
        I.i_brand,
        I.i_category,
        D.d_year
    FROM 
        web_sales WS
    JOIN 
        customer C ON WS.ws_bill_customer_sk = C.c_customer_sk
    JOIN 
        item I ON WS.ws_item_sk = I.i_item_sk
    JOIN 
        date_dim D ON WS.ws_sold_date_sk = D.d_date_sk
    WHERE 
        C.c_birth_year BETWEEN 1970 AND 1990 
        AND D.d_year = 2023
),
CategorySales AS (
    SELECT 
        i_category, 
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(*) AS transaction_count
    FROM 
        SalesData
    GROUP BY 
        i_category
),
TopCategories AS (
    SELECT 
        i_category, 
        total_sales, 
        transaction_count,
        RANK() OVER (ORDER BY total_sales DESC) AS category_rank
    FROM 
        CategorySales
)
SELECT 
    TC.i_category, 
    TC.total_sales, 
    TC.transaction_count
FROM 
    TopCategories TC
WHERE 
    TC.category_rank <= 10
ORDER BY 
    TC.total_sales DESC;
