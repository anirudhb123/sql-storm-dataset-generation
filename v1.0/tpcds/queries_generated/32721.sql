
WITH RECURSIVE SalesAnalysis AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (
            SELECT MIN(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_sales_price) > (
            SELECT AVG(ws_sales_price) 
            FROM web_sales 
            WHERE ws_sold_date_sk > (
                SELECT MAX(d_date_sk) 
                FROM date_dim 
                WHERE d_year = 2022
            )
        )
    
    UNION ALL
    
    SELECT 
        cs_item_sk, 
        SUM(cs_sales_price), 
        COUNT(cs_order_number) 
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (
            SELECT MIN(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        cs_item_sk
    HAVING 
        SUM(cs_sales_price) > (
            SELECT AVG(cs_sales_price) 
            FROM catalog_sales 
            WHERE cs_sold_date_sk > (
                SELECT MAX(d_date_sk) 
                FROM date_dim 
                WHERE d_year = 2022
            )
        )
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(CASE WHEN ws_item_sk IS NOT NULL THEN 1 END) AS item_count,
        SUM(ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk, hd.hd_buy_potential
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_paid,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > 1000
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound,
    COALESCE(SA.total_sales, 0) AS online_sales,
    COALESCE(TC.total_paid, 0) AS total_paid,
    CASE WHEN TC.rank IS NOT NULL THEN 'Top customer' ELSE 'Regular customer' END AS customer_status
FROM 
    Customer c
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN 
    SalesAnalysis SA ON c.c_customer_sk = SA.ws_item_sk
LEFT JOIN 
    TopCustomers TC ON c.c_customer_id = TC.c_customer_id
WHERE 
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    AND (c.c_birth_year < 1970 OR c.c_birth_year IS NULL)
ORDER BY 
    online_sales DESC, 
    c.c_last_name, 
    c.c_first_name;
