
WITH RECURSIVE sales_data AS (
    SELECT 
        ss.store_sk,
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM
        store_sales ss
    WHERE
        ss.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.store_sk, ss.sold_date_sk, ss.item_sk
    UNION ALL
    SELECT 
        sd.store_sk,
        sd.sold_date_sk,
        sd.item_sk,
        sd.total_quantity + (SELECT COALESCE(SUM(ss2.ss_quantity), 0) 
                              FROM store_sales ss2 
                              WHERE ss2.store_sk = sd.store_sk 
                              AND ss2.sold_date_sk = sd.sold_date_sk 
                              AND ss2.item_sk = sd.item_sk AND ss2.sold_date_sk < sd.sold_date_sk) AS total_quantity,
        sd.total_sales + (SELECT COALESCE(SUM(ss3.ss_ext_sales_price), 0) 
                           FROM store_sales ss3 
                           WHERE ss3.store_sk = sd.store_sk 
                           AND ss3.sold_date_sk = sd.sold_date_sk 
                           AND ss3.item_sk = sd.item_sk AND ss3.sold_date_sk < sd.sold_date_sk) AS total_sales
    FROM 
        sales_data sd
    WHERE 
        sd.sold_date_sk > (SELECT MIN(sold_date_sk) FROM store_sales)
)
SELECT 
    s.store_sk,
    s.item_sk,
    s.total_quantity,
    s.total_sales,
    DENSE_RANK() OVER (PARTITION BY s.store_sk ORDER BY s.total_sales DESC) AS sales_rank
FROM 
    sales_data s
JOIN 
    item i ON s.item_sk = i.i_item_sk
JOIN 
    customer c ON (c.c_customer_sk = (SELECT MAX(cc.cc_customer_sk) FROM customer cc WHERE cc.c_current_addr_sk IS NOT NULL))
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE 
    cd.cd_marital_status = 'M' AND 
    cd.cd_gender = 'F' AND 
    (cd.cd_purchase_estimate BETWEEN 100 AND 150) AND
    (i.i_current_price IS NOT NULL AND 
     i.i_current_price > 0 AND 
     i.i_category = 'Electronics')
ORDER BY 
    s.store_sk, sales_rank;
