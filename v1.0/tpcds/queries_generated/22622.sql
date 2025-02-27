
WITH RankedSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer_demographics cd
),
ItemTrends AS (
    SELECT 
        i.i_item_sk,
        AVG(ws.ws_sales_price) AS average_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
    HAVING 
        AVG(ws.ws_sales_price) < (SELECT AVG(ws_ext_sales_price) FROM web_sales)
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    cd.credit_rating,
    SUM(rs.total_sales) AS customer_total_sales,
    i.average_price,
    it.order_count
FROM 
    RankedSales rs
JOIN 
    customer c ON rs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    ItemTrends i ON i.i_item_sk = (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_ship_customer_sk = c.c_customer_sk ORDER BY ws.ws_ext_sales_price DESC LIMIT 1)
LEFT JOIN 
    (SELECT DISTINCT cr.cr_returning_customer_sk FROM catalog_returns cr WHERE cr.cr_return_quantity IS NOT NULL) AS return_customers 
    ON c.c_customer_sk = return_customers.cr_returning_customer_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics WHERE cd_gender = 'M') 
    AND i.average_price IS NOT NULL
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    cd.credit_rating, 
    i.average_price, 
    it.order_count
HAVING 
    SUM(rs.total_sales) > (SELECT COALESCE(MAX(sr_return_amt), 0) FROM store_returns sr WHERE sr.sr_return_quantity > 0)
ORDER BY 
    customer_total_sales DESC
LIMIT 50;
