
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_id, 
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
), FilteredSales AS (
    SELECT 
        rcs.c_customer_id,
        rcs.total_orders,
        rcs.total_sales
    FROM 
        RankedCustomerSales rcs
    WHERE 
        rcs.sales_rank <= 10 AND
        rcs.total_orders IS NOT NULL
), CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
), SelectedDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.customer_count
    FROM 
        CustomerDemographics cd
    WHERE 
        cd.cd_purchase_estimate > 1000
        AND cd.cd_credit_rating IN ('Good', 'Excellent')
)
SELECT 
    fs.c_customer_id,
    fs.total_orders,
    fs.total_sales,
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_purchase_estimate,
    sd.customer_count
FROM 
    FilteredSales fs
JOIN 
    SelectedDemographics sd ON fs.total_sales > 5000
ORDER BY 
    fs.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
UNION ALL
SELECT 
    NULL AS c_customer_id,
    COUNT(*) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    NULL AS cd_purchase_estimate,
    COUNT(DISTINCT c.c_customer_id) AS customer_count
FROM 
    web_sales ws
LEFT JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
WHERE 
    ws.ws_sales_price IS NOT NULL 
    AND ws.ws_shipping_cost IS NULL
    AND (SELECT COUNT(*)
         FROM store_sales ss 
         WHERE ss.ss_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales))
    > 50
GROUP BY 
    (SELECT NULL);
