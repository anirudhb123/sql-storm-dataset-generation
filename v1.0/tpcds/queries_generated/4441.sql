
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
CTE_High_Spenders AS (
    SELECT 
        customer_sales.c_customer_id,
        customer_sales.total_sales,
        RANK() OVER (ORDER BY customer_sales.total_sales DESC) AS sales_rank
    FROM 
        CTE_Customer_Sales customer_sales
    WHERE 
        customer_sales.total_sales > 1000
),
CTE_Address_Info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
CTE_Sales_By_City AS (
    SELECT 
        ai.ca_city,
        ai.ca_state,
        SUM(sales.total_sales) AS city_sales
    FROM 
        CTE_Address_Info ai
    JOIN 
        CTE_Customer_Sales cs ON ai.customer_count > 0 
        AND cs.c_customer_id IN (SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk = ai.ca_address_sk)
    GROUP BY 
        ai.ca_city, ai.ca_state
)

SELECT 
    hs.c_customer_id,
    hs.total_sales,
    sales_by_city.city_sales,
    CASE 
        WHEN hs.sales_rank <= 10 THEN 'Top 10%'
        ELSE 'Other'
    END AS rank_category,
    a.ca_city,
    a.ca_state
FROM 
    CTE_High_Spenders hs
LEFT JOIN 
    CTE_Sales_By_City sales_by_city ON sales_by_city.city_sales > 0 
LEFT JOIN 
    customer_address a ON hs.c_customer_id IN 
        (SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk)
ORDER BY 
    hs.total_sales DESC, sales_by_city.city_sales DESC;
