
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ship_customer_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.ws_ext_sales_price DESC) AS dr
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
AggregateData AS (
    SELECT 
        r.bill_customer_sk,
        COUNT(*) AS total_orders,
        SUM(r.ws_ext_sales_price) AS total_sales 
    FROM 
        RankedSales r
    WHERE 
        r.rn <= 5
    GROUP BY 
        r.bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        a.ca_city,
        a.ca_state,
        a.ca_country
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    d.bill_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    d.total_orders,
    d.total_sales,
    CASE 
        WHEN d.total_sales IS NULL THEN 'NO SALES'
        WHEN d.total_sales > 1000 THEN 'HIGH SPENDER'
        WHEN d.total_sales BETWEEN 500 AND 1000 THEN 'MEDIUM SPENDER'
        ELSE 'LOW SPENDER'
    END AS customer_segment,
    COUNT(DISTINCT CASE WHEN d.total_orders > 2 THEN d.ws_order_number END) AS frequent_buyer_count
FROM 
    AggregateData d
RIGHT JOIN 
    CustomerDetails cd ON d.bill_customer_sk = cd.c_customer_sk
WHERE 
    (cd.cd_gender IS NOT NULL AND cd.cd_marital_status IS NOT NULL) 
    OR (cd.ca_city IS NULL AND cd.ca_state IS NULL AND cd.ca_country IS NULL)
GROUP BY 
    d.bill_customer_sk, cd.c_first_name, cd.c_last_name, d.total_orders, d.total_sales
ORDER BY 
    total_sales DESC NULLS LAST;
