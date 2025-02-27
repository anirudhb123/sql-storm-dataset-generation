
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.web_site_id) AS total_quantity,
        LEAD(ws.ws_sales_price) OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sold_date_sk) AS next_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(NULLIF(cd.cd_credit_rating, 'low'), 'unknown') AS adjusted_credit_rating,
        cd.cd_purchase_estimate * 1.1 AS potential_purchase
    FROM 
        customer_demographics cd
),
SalesWithDemographics AS (
    SELECT 
        s.web_site_id,
        s.ws_sold_date_sk,
        c.c_customer_id,
        d.cd_gender,
        d.adjusted_credit_rating,
        s.ws_net_profit,
        s.total_quantity
    FROM 
        RankedSales s
    JOIN 
        customer c ON s.ws_item_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE 
        s.rank_profit <= 10 AND
        d.cd_marital_status IN ('M', 'S') AND
        d.potential_purchase > 5000
)
SELECT 
    sd.web_site_id,
    COUNT(DISTINCT sd.c_customer_id) AS unique_customers,
    AVG(sd.ws_net_profit) AS average_profit,
    SUM(sd.total_quantity) AS total_sales,
    CASE 
        WHEN AVG(sd.ws_net_profit) > 1000 THEN 'High Profit'
        WHEN AVG(sd.ws_net_profit) > 500 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    SalesWithDemographics sd
GROUP BY 
    sd.web_site_id
HAVING 
    COUNT(DISTINCT sd.c_customer_id) > 5
ORDER BY 
    total_sales DESC,
    web_site_id ASC
LIMIT 50;
