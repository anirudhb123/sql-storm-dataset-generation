
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        cs.cs_order_number,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_item_sk) AS number_of_unique_items
    FROM 
        web_sales ws
    JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451595  -- Arbitrary date range
    GROUP BY 
        ws.web_site_id, cs.cs_order_number
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        AVG(cd.cd_dep_count) AS average_department_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'S'  -- Single male customers
    GROUP BY 
        cd.cd_demo_sk
),
RankedReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_item_sk ORDER BY SUM(cr.cr_return_quantity) DESC) AS rank
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_quantity > 0
    GROUP BY 
        cr.cr_item_sk
    HAVING 
        SUM(cr.cr_return_quantity) > 5  -- Items with significant returns
)
SELECT 
    cd.cd_demo_sk,
    sales.web_site_id,
    sales.total_sales,
    sales.number_of_unique_items,
    returns.total_returned,
    cd.max_purchase_estimate,
    cd.average_department_count
FROM 
    SalesData sales
JOIN 
    CustomerDemographics cd ON sales.number_of_unique_items > cd.average_department_count
LEFT JOIN 
    RankedReturns returns ON returns.cr_item_sk = sales.cs_order_number
ORDER BY 
    total_sales DESC
LIMIT 100;
