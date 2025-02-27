
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), ItemDetails AS (
    SELECT 
        i_item_sk,
        i_product_name,
        CONCAT(i_brand, ' ', i_category) AS product_line,
        i_current_price,
        LEAD(i_current_price) OVER (PARTITION BY i_item_sk ORDER BY i_item_sk) AS next_price
    FROM 
        item
), CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
), AggregateReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns 
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), SalesReturns AS (
    SELECT 
        i.i_item_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) AS net_sales
    FROM 
        ItemDetails i
    LEFT JOIN 
        (SELECT 
             ws_item_sk, 
             SUM(ws_quantity) AS total_sales 
         FROM 
             web_sales 
         GROUP BY 
             ws_item_sk) s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN 
        AggregateReturns r ON i.i_item_sk = r.sr_item_sk
)
SELECT 
    sr.i_item_sk,
    sr.product_line,
    sr.total_sales,
    sr.total_returns,
    sr.net_sales,
    d.cd_gender,
    d.cd_marital_status
FROM 
    SalesReturns sr
JOIN 
    CustomerDemographics d ON d.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = (SELECT MAX(c_customer_sk) FROM customer WHERE c_current_addr_sk IS NOT NULL))
WHERE 
    sr.net_sales > 0
ORDER BY 
    sr.net_sales DESC
LIMIT 100;
