
WITH RankedSales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_profit,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_profit DESC) AS profit_rank
    FROM
        catalog_sales cs
    WHERE
        cs.cs_sold_date_sk BETWEEN 1 AND 365
),

CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),

SalesByCustomer AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
    GROUP BY
        ws.ws_bill_customer_sk
),

ReturnsAndSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(r.total_returned_quantity), 0) AS total_returns,
        COALESCE(s.total_profit, 0) AS total_profit,
        s.order_count
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns r ON c.c_customer_sk = r.cr_returning_customer_sk
    LEFT JOIN 
        SalesByCustomer s ON c.c_customer_sk = s.customer_sk
    GROUP BY 
        c.c_customer_id, s.order_count
),

FinalAggregation AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT r.c_customer_id) AS unique_customers,
        AVG(r.total_profit) AS avg_profit_per_customer,
        SUM(CASE WHEN r.total_returns > 0 THEN 1 ELSE 0 END) AS customers_with_returns
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        ReturnsAndSales r ON c.c_customer_id = r.c_customer_id
    GROUP BY 
        ca.ca_city
)

SELECT 
    fa.ca_city,
    fa.unique_customers,
    fa.avg_profit_per_customer,
    fa.customers_with_returns,
    CASE 
        WHEN fa.avg_profit_per_customer IS NULL THEN 'No Sales'
        WHEN fa.avg_profit_per_customer < 100 THEN 'Low Profit'
        ELSE 'Profitable'
    END AS profitability_status
FROM 
    FinalAggregation fa
ORDER BY 
    fa.unique_customers DESC, fa.avg_profit_per_customer DESC
FETCH FIRST 10 ROWS ONLY;
