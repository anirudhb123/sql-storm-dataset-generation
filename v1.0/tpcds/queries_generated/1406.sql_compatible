
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 10.00
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returned,
        COUNT(wr_return_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
StoreAggregates AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(ss_ticket_number) AS total_sales_count
    FROM 
        store_sales ss
    GROUP BY 
        s_store_sk
),
AvgSales AS (
    SELECT 
        AVG(total_net_paid) AS average_sales
    FROM 
        StoreAggregates
)

SELECT 
    ca.ca_address_id,
    cd.cd_gender,
    cd.cd_marital_status,
    rs.ws_item_sk,
    COALESCE(cr.total_returned, 0) AS total_returns,
    sa.total_net_paid,
    avg.average_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    RankedSales rs ON rs.rnk = 1
LEFT JOIN 
    CustomerReturns cr ON cr.wr_returning_customer_sk = c.c_customer_sk
JOIN 
    StoreAggregates sa ON sa.s_store_sk = (SELECT s_store_sk FROM store WHERE s_store_id = 'ST100' LIMIT 1)
CROSS JOIN 
    AvgSales avg
WHERE 
    cd.cd_marital_status = 'M'
    AND (rs.ws_sales_price IS NOT NULL AND rs.ws_sales_price < 100.00)
ORDER BY 
    ca.ca_address_id;
