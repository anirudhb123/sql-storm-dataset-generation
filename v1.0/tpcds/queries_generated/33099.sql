
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        ws_sold_date_sk, 
        ws_sales_price, 
        ws_quantity, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
), 
AggregateSales AS (
    SELECT 
        item.i_item_id,
        SUM(sales.ws_sales_price * sales.ws_quantity) AS total_sales,
        AVG(sales.ws_sales_price) AS avg_price,
        COUNT(DISTINCT sales.ws_item_sk) AS sales_count
    FROM 
        SalesCTE sales
    JOIN 
        item item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rn <= 5
    GROUP BY 
        item.i_item_id
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
)
SELECT 
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    demo.cd_gender,
    sales.total_sales,
    sales.avg_price,
    demo.hd_income_band_sk,
    CASE 
        WHEN sales.total_sales IS NULL THEN 'No Sales'
        WHEN sales.total_sales > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value,
    STRING_AGG(DISTINCT item.i_item_id, ', ') AS items_purchased
FROM 
    customer cust
LEFT JOIN 
    web_sales ws ON cust.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    AggregateSales sales ON ws.ws_item_sk = sales.ws_item_sk
LEFT JOIN 
    CustomerDemographics demo ON cust.c_current_cdemo_sk = demo.cd_demo_sk
WHERE 
    cust.c_birth_year < 1980
GROUP BY 
    cust.c_customer_id, 
    cust.c_first_name, 
    cust.c_last_name, 
    demo.cd_gender, 
    sales.total_sales, 
    sales.avg_price, 
    demo.hd_income_band_sk
ORDER BY 
    total_sales DESC
FETCH FIRST 100 ROWS ONLY;
