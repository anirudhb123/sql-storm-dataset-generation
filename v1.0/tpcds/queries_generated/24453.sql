
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        MAX(cr_return_amount) AS max_return_amount
    FROM 
        catalog_returns
    WHERE 
        cr_returning_customer_sk IS NOT NULL
    GROUP BY 
        cr_returning_customer_sk,
        cr_item_sk
),
SalesCalculations AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_ship_customer_sk
),
CustomerDemographicsEnhanced AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer_demographics cd
)
SELECT 
    c.c_customer_id,
    ca.ca_street_name,
    ca.ca_city,
    ca.ca_state,
    COALESCE(SUM(sc.total_sold_quantity), 0) AS total_sold_quantity,
    COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rd.max_return_amount, 0) AS max_return_amount,
    cd.customer_value,
    cd.gender_rank
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    SalesCalculations sc ON c.c_customer_sk = sc.ws_ship_customer_sk
LEFT JOIN 
    CustomerReturns r ON c.c_customer_sk = r.cr_returning_customer_sk
LEFT JOIN 
    CustomerDemographicsEnhanced cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
FULL OUTER JOIN 
    (SELECT DISTINCT 
         cr.refunded_customer_sk 
     FROM 
         catalog_returns cr 
     WHERE 
         cr_refunded_cash IS NOT NULL) refunded ON 
    c.c_customer_sk = refunded.refunded_customer_sk
WHERE 
    (ca.ca_state = 'CA' OR ca.ca_state IS NULL)
    AND cd.gender_rank < 5
GROUP BY 
    c.c_customer_id, 
    ca.ca_street_name, 
    ca.ca_city, 
    ca.ca_state,
    cd.customer_value,
    cd.gender_rank
ORDER BY 
    c.c_customer_id, 
    total_sold_quantity DESC;
