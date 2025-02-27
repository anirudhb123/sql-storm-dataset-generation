
WITH RankedSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_dep_college_count,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 100 THEN 'Low Value'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium Value'
            ELSE 'High Value'
        END AS purchase_segment
    FROM 
        customer_demographics cd
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_sales_price) AS total_sales,
    AVG(cs.cs_net_paid) AS avg_net_paid,
    MAX(cs.cs_ext_discount_amt) AS max_discount,
    COUNT(DISTINCT cs.cs_item_sk) AS unique_items_sold,
    cd.cd_gender,
    cd.purchase_segment,
    MAX(R.total_net_profit) AS highest_net_profit
FROM 
    store_sales cs
LEFT JOIN 
    customer c ON cs.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    RankedSales R ON c.c_customer_id = R.c_customer_id
WHERE 
    cs.ss_sold_date_sk >= DATEADD(DAY, -30, CURRENT_DATE)
    AND ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city, cd.cd_gender, cd.purchase_segment
HAVING 
    COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY 
    total_sales DESC;
