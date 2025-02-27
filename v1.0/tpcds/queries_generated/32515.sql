
WITH RECURSIVE RankedSales AS (
    SELECT 
        ss.sold_date_sk, 
        ss.item_sk, 
        ss.store_sk, 
        ss.sales_price, 
        ss.ext_sales_price, 
        ss.ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY ss.ext_sales_price DESC) AS rn
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
TotalSales AS (
    SELECT 
        item_sk, 
        SUM(ext_sales_price) AS total_sales
    FROM 
        RankedSales
    WHERE 
        rn <= 5
    GROUP BY 
        item_sk
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ss.ticket_number) AS purchase_count,
        SUM(COALESCE(ss.ext_sales_price, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
FilteredDemo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerStatistics c
    INNER JOIN 
        TotalSales cs ON c.c_customer_sk = cs.item_sk
    WHERE 
        c.total_spent > 1000
)
SELECT 
    fd.cd_gender,
    COUNT(fd.c_customer_sk) AS customer_count,
    AVG(fd.total_sales) AS avg_sales
FROM 
    FilteredDemo fd
GROUP BY 
    fd.cd_gender
HAVING 
    COUNT(fd.c_customer_sk) > 10
ORDER BY 
    avg_sales DESC;
