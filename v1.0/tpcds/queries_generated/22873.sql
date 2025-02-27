
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand
    FROM 
        item
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        COALESCE(d.cd_marital_status, 'Unknown') AS marital_status,
        MAX(d.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer c
    LEFT JOIN
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, d.cd_gender
),
SalesSummary AS (
    SELECT 
        ir.i_item_sk,
        ir.i_item_desc,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        (COALESCE(SUM(ws.ws_ext_sales_price), 0) + COALESCE(SUM(ss.ss_ext_sales_price), 0)) AS grand_total
    FROM 
        ItemDetails ir
    LEFT JOIN 
        web_sales ws ON ir.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        store_sales ss ON ir.i_item_sk = ss.ss_item_sk
    GROUP BY 
        ir.i_item_sk, ir.i_item_desc
)

SELECT 
    item_details.i_item_sk,
    item_details.i_item_desc,
    item_details.i_current_price,
    ranked_sales.total_sales AS web_sales,
    COALESCE(sales_summary.total_web_sales, 0) AS total_web_sales,
    COALESCE(sales_summary.total_store_sales, 0) AS total_store_sales,
    sales_summary.grand_total,
    customer_demographics.cd_gender,
    customer_demographics.marital_status,
    CASE 
        WHEN customer_demographics.max_purchase_estimate > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    ItemDetails item_details
LEFT JOIN 
    RankedSales ranked_sales ON item_details.i_item_sk = ranked_sales.ws_item_sk
LEFT JOIN 
    SalesSummary sales_summary ON item_details.i_item_sk = sales_summary.i_item_sk
LEFT JOIN 
    CustomerDemographics customer_demographics ON customer_demographics.c_customer_sk = (
        SELECT 
            c.c_customer_sk 
        FROM 
            customer c 
        ORDER BY 
            RANDOM() 
        LIMIT 1
    )
WHERE 
    (ranked_sales.sales_rank IS NULL OR ranked_sales.sales_rank < 10)
    AND (customer_demographics.marital_status IS NOT NULL OR customer_demographics.cd_gender = 'F')
ORDER BY 
    grand_total DESC
LIMIT 100;
