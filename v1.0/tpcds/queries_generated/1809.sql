
WITH SalesData AS (
    SELECT 
        ws_sales_price,
        ws_quantity,
        ws_bill_customer_sk,
        ws_sold_date_sk,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS SalesRank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459000 AND 2459005
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    COUNT(sd.ws_sales_price) AS total_sales_count,
    SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales_amount,
    STRING_AGG(DISTINCT cd.hd_buy_potential) AS distinct_buy_potentials
FROM 
    CustomerData cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.hd_income_band_sk IS NOT NULL 
    AND cd.cd_gender = 'F'
GROUP BY 
    cd.c_first_name, cd.c_last_name
HAVING 
    COUNT(sd.ws_sales_price) > 1
ORDER BY 
    total_sales_amount DESC
FETCH FIRST 10 ROWS ONLY;

WITH ItemSales AS (
    SELECT 
        i.i_item_id,
        SUM(Ws.ws_sales_price * Ws.ws_quantity) AS total_item_sales
    FROM 
        item i
    JOIN 
        web_sales Ws ON i.i_item_sk = Ws.ws_item_sk
    WHERE 
        i.i_rec_start_date < CURRENT_DATE AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
    GROUP BY 
        i.i_item_id
)
SELECT 
    i.i_item_id,
    COALESCE(total_item_sales, 0) AS total_sales
FROM 
    item i
LEFT JOIN 
    ItemSales its ON i.i_item_id = its.i_item_id
WHERE 
    i.i_color IS NOT NULL
ORDER BY 
    total_sales DESC
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;

SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
    COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_first_name, c.c_last_name
HAVING 
    total_store_sales + total_catalog_sales + total_web_sales >= 1000
ORDER BY 
    total_store_sales DESC, total_catalog_sales DESC, total_web_sales DESC;
