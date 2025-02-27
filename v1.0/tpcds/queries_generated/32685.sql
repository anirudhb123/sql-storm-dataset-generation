
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS return_orders
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
PopularItems AS (
    SELECT 
        i_item_id, 
        i_product_name,
        s_store_name,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(cs_ext_sales_price) DESC) AS sale_rank
    FROM 
        catalog_sales cs
    INNER JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN 
        store s ON cs.cs_warehouse_sk = s.s_store_sk
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        i_item_id, i_product_name, s_store_name
),
FinalMetrics AS (
    SELECT 
        c.c_customer_id,
        COALESCE(DATEDIFF(CURRENT_DATE, c.c_birth_day), 0) AS age,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        COALESCE(si.total_catalog_sales, 0) AS catalog_sales,
        COALESCE(sr.total_returned, 0) AS total_returns,
        RANK() OVER (ORDER BY COALESCE(si.total_catalog_sales, 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        (SELECT 
            ws_bill_customer_sk,
            SUM(ws_ext_sales_price) AS total_catalog_sales
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk) AS si ON c.c_customer_sk = si.ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturns sr ON c.c_customer_sk = sr.wr_returning_customer_sk
    WHERE 
        age IS NOT NULL AND age > 0
)
SELECT 
    fm.c_customer_id,
    fm.age,
    fm.cd_gender,
    fm.cd_marital_status,
    fm.ca_city,
    fm.catalog_sales,
    fm.total_returns,
    RANK() OVER (ORDER BY fm.catalog_sales DESC) AS rank_sales
FROM 
    FinalMetrics fm
WHERE 
    fm.catalog_sales > 0
ORDER BY 
    rank_sales
FETCH FIRST 100 ROWS ONLY;
