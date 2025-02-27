
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        ws_item_sk
),
CustomerAddressInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    r.total_sales,
    r.order_count,
    ca.ca_city,
    ca.ca_state
FROM 
    RankedSales r
JOIN 
    web_sales ws ON r.ws_item_sk = ws.ws_item_sk
JOIN 
    CustomerAddressInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC, 
    c.ca_city;
