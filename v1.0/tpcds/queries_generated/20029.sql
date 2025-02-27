
WITH RECURSIVE IncomeStats AS (
    SELECT 
        hd_demo_sk,
        ib_income_band_sk,
        SUM(hd_dep_count) AS total_dep_count,
        COUNT(hd_vehicle_count) AS total_vehicle_count
    FROM 
        household_demographics
    LEFT JOIN 
        income_band ON hd_income_band_sk = ib_income_band_sk
    WHERE 
        ib_lower_bound IS NOT NULL
    GROUP BY 
        hd_demo_sk, ib_income_band_sk
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        COUNT(cr_order_number) AS total_returns
    FROM 
        catalog_returns cr
    WHERE 
        cr_return_amount > 10
    GROUP BY 
        cr.returning_customer_sk
),
SalesInfo AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451873 AND 2451924 -- Dates for a given month
    GROUP BY 
        ws_ship_customer_sk
),
RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_return_quantity, 0) AS total_returns,
        DENSE_RANK() OVER (ORDER BY COALESCE(s.total_sales, 0) DESC, COALESCE(r.total_return_quantity, 0) ASC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        SalesInfo s ON c.c_customer_sk = s.ws_ship_customer_sk
    LEFT JOIN 
        CustomerReturns r ON c.c_customer_sk = r.returning_customer_sk
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_sales,
    rc.total_returns,
    CASE 
        WHEN rc.rank <= 10 THEN 'Top Customer'
        WHEN rc.total_returns > rc.total_sales * 0.2 THEN 'Frequent Returner'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    RankedCustomers rc
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM customer_demographics cd 
        WHERE 
            cd.cd_demo_sk = rc.c_customer_sk
            AND cd.cd_marital_status = 'S'  -- Marital status check for singles only
    )
ORDER BY 
    rc.rank;
