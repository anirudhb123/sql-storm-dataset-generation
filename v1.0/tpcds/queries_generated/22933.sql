
WITH RecursiveCustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN 'Band Exists'
            ELSE 'No Band'
        END AS income_band_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        (c.c_birth_month IS NULL OR c.c_birth_month BETWEEN 1 AND 6)
        AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_sold_date_sk
),
BestDay AS (
    SELECT 
        d.d_date,
        sd.total_sales,
        sd.total_orders,
        DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS rank_sales
    FROM 
        date_dim d
    JOIN 
        SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.c_customer_sk,
    bc.d_date AS best_sales_date,
    bc.total_sales,
    COALESCE((
        SELECT 
            COUNT(*)
        FROM 
            store_returns sr
        WHERE 
            sr.sr_customer_sk = c.c_customer_sk
            AND sr.sr_return_quantity > 0
    ), 0) AS total_returns,
    (CASE 
        WHEN bc.rank_sales = 1 THEN 'Best Customer'
        ELSE 'Regular Customer'
    END) AS customer_status
FROM 
    RecursiveCustomerData c
LEFT JOIN 
    BestDay bc ON c.rn = 1 AND c.c_customer_sk = (SELECT MIN(cus.c_customer_sk) FROM RecursiveCustomerData cus WHERE cus.rn = 1)
WHERE 
    c.income_band_status IS NOT NULL
ORDER BY 
    c.c_last_name ASC,
    c.c_first_name DESC;
