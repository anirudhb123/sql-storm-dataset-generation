
WITH RankedReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cr.returned_date_sk,
        cr.returning_addr_sk,
        cr_return_quantity,
        RANK() OVER (PARTITION BY cr.returning_customer_sk ORDER BY cr.returned_date_sk DESC) AS rn
    FROM 
        catalog_returns cr
    WHERE 
        cr.returned_date_sk IS NOT NULL
),
MaxReturns AS (
    SELECT 
        returning_customer_sk,
        MAX(returned_date_sk) AS max_return_date
    FROM 
        RankedReturns
    WHERE 
        rn = 1
    GROUP BY 
        returning_customer_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        SUM(COALESCE(DISTINCT ws.ws_net_profit, 0.0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        COUNT(DISTINCT rr.returning_customer_sk) AS returns_count
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        RankedReturns rr ON c.c_customer_sk = rr.returning_customer_sk
    LEFT JOIN 
        MaxReturns mr ON rr.returning_customer_sk = mr.returning_customer_sk
    WHERE 
        (c.c_birth_month = 12 OR c.c_birth_day IS NULL)
        AND (ca.ca_city IS NOT NULL OR c.c_last_name LIKE 'A%')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city
),
IncomeStats AS (
    SELECT 
        hd.hd_demo_sk,
        COUNT(*) AS income_eligibility_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        (ib.ib_lower_bound < 50000 AND ib.ib_upper_bound IS NOT NULL) 
        OR (hd.hd_buy_potential = 'High')
    GROUP BY 
        hd.hd_demo_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.ca_city,
    cs.total_net_profit,
    cs.orders_count,
    COALESCE(is.income_eligibility_count, 0) AS income_eligibility_count
FROM 
    CustomerStats cs
LEFT JOIN 
    IncomeStats is ON cs.c_customer_sk = is.hd_demo_sk
WHERE 
    total_net_profit > (
        SELECT 
            AVG(total_net_profit)
        FROM 
            CustomerStats
    )
ORDER BY 
    total_net_profit DESC, 
    orders_count ASC
FETCH FIRST 100 ROWS ONLY;
