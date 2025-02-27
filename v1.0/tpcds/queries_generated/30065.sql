
WITH RECURSIVE TotalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk

    UNION ALL

    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(cs_order_number) AS order_count
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        cs_bill_customer_sk
),
RankedSales AS (
    SELECT 
        customer.c_customer_id,
        COALESCE(ts.total_profit, 0) AS total_profit,
        COALESCE(ts.order_count, 0) AS order_count,
        DENSE_RANK() OVER (ORDER BY COALESCE(ts.total_profit, 0) DESC) AS profit_rank
    FROM 
        customer customer
    LEFT JOIN 
        (SELECT 
            ws_bill_customer_sk, SUM(ts.total_profit) AS total_profit, SUM(ts.order_count) AS order_count
         FROM 
            TotalSales ts
         GROUP BY 
            ws_bill_customer_sk) ts ON customer.c_customer_sk = ts.ws_bill_customer_sk
),
AddressDetails AS (
    SELECT 
        ca_address_id,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_state IS NOT NULL
)
SELECT 
    rs.c_customer_id,
    ad.ca_address_id,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    rs.total_profit,
    rs.order_count,
    CASE
        WHEN rs.total_profit > 1000 THEN 'High Value'
        WHEN rs.total_profit > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    RankedSales rs
LEFT OUTER JOIN 
    AddressDetails ad ON ad.ca_address_id = (SELECT ca_address_id FROM customer_address WHERE ca_address_sk = customer.c_current_addr_sk)
WHERE 
    rs.profit_rank <= 10
ORDER BY 
    rs.total_profit DESC;
