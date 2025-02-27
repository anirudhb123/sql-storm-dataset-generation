
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020 AND (c.c_birth_year BETWEEN 1980 AND 2000 OR c.c_birth_year IS NULL)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
), 
AnnualRankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.d_year,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerStats AS cs
), 
SelectedCustomers AS (
    SELECT 
        ars.c_customer_sk,
        ars.c_first_name,
        ars.c_last_name,
        ars.d_year,
        ars.total_sales,
        ars.order_count
    FROM 
        AnnualRankedSales AS ars
    WHERE 
        ars.sales_rank <= 5
), 
CustomerDetails AS (
    SELECT 
        sc.c_customer_sk,
        sc.c_first_name,
        sc.c_last_name,
        COALESCE(ad.ca_city, 'Unknown City') AS address_city,
        COALESCE(ad.ca_state, 'Unknown State') AS address_state,
        SUM(CASE WHEN f_count < 1 THEN 1 ELSE 0 END) AS no_family_count
    FROM 
        SelectedCustomers AS sc
    LEFT JOIN 
        customer_address AS ad ON ad.ca_address_sk = sc.c_customer_sk
    LEFT JOIN 
        household_demographics AS hd ON hd.hd_demo_sk = sc.c_customer_sk
    WHERE 
        (ad.ca_city IS NOT NULL OR ad.ca_state IS NOT NULL)
    GROUP BY 
        sc.c_customer_sk, sc.c_first_name, sc.c_last_name, ad.ca_city, ad.ca_state
)

SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.address_city,
    cd.address_state,
    cd.total_sales,
    cd.order_count,
    (CASE 
        WHEN cd.no_family_count IS NULL THEN 'No Family'
        ELSE 'Family'
    END) AS family_status
FROM 
    CustomerDetails AS cd
ORDER BY 
    cd.total_sales DESC, cd.c_last_name ASC
LIMIT 10;

