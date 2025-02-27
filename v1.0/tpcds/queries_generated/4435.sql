
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_sales_price) DESC) AS site_sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT c.c_customer_id) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
SalesReturns AS (
    SELECT 
        sr_returned_date_sk,
        CAST(SUM(sr_return_quantity) AS DECIMAL(10, 2)) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
)
SELECT 
    ca.ca_state,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
    SUM(sr.total_returned_amt) AS total_returns,
    cs.total_customers,
    cs.avg_purchase_estimate,
    cs.female_count,
    cs.male_count,
    COUNT(DISTINCT s.s_store_sk) AS store_count,
    SUM(CASE WHEN rs.site_sales_rank = 1 THEN rs.ws_quantity ELSE 0 END) AS top_sales_quantity
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    SalesReturns sr ON ws.ws_sold_date_sk = sr.sr_returned_date_sk
JOIN 
    CustomerStatistics cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    RankedSales rs ON ws.ws_item_sk = rs.ws_item_sk
JOIN 
    store s ON ws.ws_ship_addr_sk = s.s_store_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    ca.ca_state, cs.total_customers, cs.avg_purchase_estimate, cs.female_count, cs.male_count
HAVING 
    SUM(ws.ws_sales_price * ws.ws_quantity) > 10000
ORDER BY 
    total_sales DESC;
