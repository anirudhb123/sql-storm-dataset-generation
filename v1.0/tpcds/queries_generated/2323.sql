
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS ProfitRank,
        cd.cd_gender,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2600
)
SELECT 
    sd.ws_order_number,
    SUM(sd.ws_quantity) AS TotalQuantity,
    COUNT(sd.ws_item_sk) AS TotalItems,
    AVG(sd.ws_ext_sales_price) AS AvgSalesPrice,
    SUM(sd.ws_net_profit) AS TotalNetProfit,
    sd.cd_gender,
    sd.ca_state
FROM 
    SalesData sd
WHERE 
    sd.ProfitRank <= 10
GROUP BY 
    sd.ws_order_number, sd.cd_gender, sd.ca_state
HAVING 
    SUM(sd.ws_quantity) > 100
ORDER BY 
    TotalNetProfit DESC;

WITH ReturningCustomers AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS TotalReturns,
        SUM(sr.sr_return_amt_inc_tax) AS TotalReturnedAmount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
    HAVING 
        SUM(sr.sr_return_quantity) > 5
)
SELECT 
    c.c_customer_id,
    COALESCE(rc.TotalReturns, 0) AS ReturnsCount,
    COALESCE(rc.TotalReturnedAmount, 0) AS ReturnsAmount
FROM 
    customer c
LEFT JOIN 
    ReturningCustomers rc ON c.c_customer_sk = rc.sr_customer_sk
WHERE 
    c.c_preferred_cust_flag = 'Y'
UNION ALL
SELECT 
    'TOTAL' AS c_customer_id,
    SUM(COALESCE(rc.TotalReturns, 0)),
    SUM(COALESCE(rc.TotalReturnedAmount, 0))
FROM 
    customer c
LEFT JOIN 
    ReturningCustomers rc ON c.c_customer_sk = rc.sr_customer_sk
WHERE 
    c.c_preferred_cust_flag = 'Y';
