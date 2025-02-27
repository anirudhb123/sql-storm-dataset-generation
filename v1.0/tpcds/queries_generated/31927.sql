
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 20210101 AND 20211231
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS rank_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
CitySales AS (
    SELECT 
        ci.ca_city,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        SalesCTE s
    JOIN 
        CustomerInfo ci ON ci.c_customer_sk = s.ws_customer_sk
    JOIN 
        web_sales ws ON ws.ws_order_number = s.ws_order_number
    GROUP BY 
        ci.ca_city
),
RankedCities AS (
    SELECT
        ca_city,
        total_sales,
        order_count,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS city_rank
    FROM
        CitySales
)
SELECT 
    rc.ca_city,
    rc.total_sales,
    rc.order_count,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status
FROM  
    RankedCities rc
LEFT JOIN 
    CustomerInfo ci ON rc.ca_city = ci.ca_city
WHERE 
    rc.city_rank <= 10
    AND ci.cd_marital_status = 'M'
    AND ci.cd_gender IS NOT NULL
ORDER BY 
    rc.total_sales DESC;
