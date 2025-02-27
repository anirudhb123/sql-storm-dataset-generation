
WITH RankedSales AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY 
        cs_item_sk
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        item.i_current_price,
        RankedSales.total_sales,
        RankedSales.order_count
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.cs_item_sk = item.i_item_sk
    WHERE 
        RankedSales.sales_rank <= 10
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ISNULL(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesByGender AS (
    SELECT 
        cd.cd_gender,
        SUM(ts.total_sales) AS total_sales_by_gender
    FROM 
        TopSellingItems ts
    JOIN 
        CustomerData cd ON ts.c_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    COALESCE(g.cd_gender, 'Unknown') AS gender,
    SUM(s.total_sales) AS total_sales,
    COUNT(s.order_count) AS total_orders,
    ROUND(SUM(s.total_sales) / NULLIF(COUNT(s.order_count), 0), 2) AS avg_sales_per_order
FROM 
    SalesByGender s
FULL OUTER JOIN 
    (SELECT DISTINCT cd_gender FROM customer_demographics) g ON s.cd_gender = g.cd_gender
GROUP BY 
    g.cd_gender
ORDER BY 
    gender;
