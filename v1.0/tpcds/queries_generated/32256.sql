
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_sold_date_sk, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
), 

CustomerSpend AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),

HighlyActiveCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent IS NULL THEN 'Unknown'
            WHEN cs.total_spent < 100 THEN 'Low'
            WHEN cs.total_spent BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS spending_band
    FROM 
        CustomerSpend cs
),

TopSales AS (
    SELECT 
        c.c_customer_id,
        cs.total_spent,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cs.total_spent DESC) AS city_rank
    FROM 
        HighlyActiveCustomers hac
    JOIN 
        customer c ON hac.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        hac.spending_band = 'High'
)

SELECT 
    ts.c_customer_id,
    ts.total_spent,
    ts.ca_city,
    CASE 
        WHEN ts.city_rank <= 5 THEN 'Top 5%' 
        WHEN ts.city_rank <= 20 THEN 'Top 20%' 
        ELSE 'Below Top 20%' 
    END AS spend_category,
    COALESCE(s.total_sales, 0) AS sales_of_web_site
FROM 
    TopSales ts
LEFT JOIN 
    (SELECT 
         web_site_sk, 
         SUM(total_sales) AS total_sales
     FROM 
         SalesCTE
     WHERE 
         sales_rank = 1
     GROUP BY 
         web_site_sk) s ON ts.c_customer_id = s.web_site_sk
WHERE 
    ts.total_spent > 0
ORDER BY 
    ts.total_spent DESC, ts.ca_city;
