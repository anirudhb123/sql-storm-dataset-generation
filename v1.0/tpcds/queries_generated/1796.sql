
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        RANK() OVER (ORDER BY r.total_sales DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        r.sales_rank <= 10
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        COUNT(DISTINCT ca.ca_state) AS state_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city
),
FinalReport AS (
    SELECT 
        hvc.c_customer_id,
        hvc.c_first_name,
        hvc.c_last_name,
        ca.ca_city,
        ca.state_count,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        CustomerAddresses ca ON TRUE
    LEFT JOIN 
        web_sales ws ON hvc.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        hvc.c_customer_id, hvc.c_first_name, hvc.c_last_name, ca.ca_city, ca.state_count
)
SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.ca_city,
    f.state_count,
    f.total_profit,
    CASE WHEN f.state_count IS NULL THEN 'No Address' ELSE 'Has Address' END AS address_status
FROM 
    FinalReport f
WHERE 
    f.total_profit > 10000
ORDER BY 
    f.total_profit DESC;
