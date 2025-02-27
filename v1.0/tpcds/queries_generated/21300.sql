
WITH RankedSales AS (
    SELECT 
        ws_cust.c_customer_id,
        ws.cs_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_cust.c_customer_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer ws_cust ON ws.ws_bill_customer_sk = ws_cust.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
),
DetailedReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount,
        AVG(wr.wr_return_fee) AS avg_return_fee
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ca.ca_city,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    COALESCE(SUM(dr.total_returned_amount), 0) AS total_returned_amount,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    STRING_AGG(DISTINCT cd.cd_gender || ':' || cd.cd_marital_status) AS demographics
FROM 
    customer_address ca
LEFT OUTER JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT OUTER JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT OUTER JOIN 
    DetailedReturns dr ON ws.ws_item_sk = dr.wr_item_sk
LEFT OUTER JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX') 
    AND (cd.cd_marital_status IS NOT NULL OR cd.cd_gender IS NULL)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(ws.ws_order_number) > 5
ORDER BY 
    total_net_profit DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
