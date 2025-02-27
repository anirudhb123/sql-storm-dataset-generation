
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 500 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 200 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_band,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.order_count,
        RANK() OVER (ORDER BY cs.order_count DESC) AS customer_rank
    FROM 
        CustomerStats cs
)
SELECT 
    ca.ca_city,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_revenue,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(RR.total_sales) AS avg_item_sales
FROM 
    customer_address ca
LEFT JOIN 
    web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk
LEFT JOIN 
    RankedSales RR ON ws.ws_item_sk = RR.ws_item_sk
WHERE 
    ca.ca_state = 'CA'
    AND EXISTS (
        SELECT 1 
        FROM TopCustomers tc 
        WHERE tc.c_customer_id = ws.ws_bill_customer_sk 
        AND tc.customer_rank <= 10
    )
GROUP BY 
    ca.ca_city
ORDER BY 
    total_revenue DESC 
LIMIT 10;
