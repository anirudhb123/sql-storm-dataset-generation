
WITH RankedSales AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.store_sk,
        ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY ss_net_profit DESC) AS rnk
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023 AND 
                d_month_seq BETWEEN 1 AND 6
        )
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
    WHERE 
        ca.ca_country IS NOT NULL
),
LowestIncomeCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        h.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        household_demographics h ON c.c_customer_sk = h.hd_demo_sk
    JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_lower_bound >= 0 AND 
        ib.ib_upper_bound <= 25000
)
SELECT 
    s.customer_name, 
    s.sales_amount,
    SALES_ENVIRONMENT = 
    CASE 
        WHEN s.sales_amount > 10000 THEN 'High'
        WHEN s.sales_amount BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_environment,
    ca.full_address,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY s.sales_amount DESC) AS state_rank
FROM (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SUM(ss_net_paid) DESC) AS customer_rank,
        c.c_customer_sk AS customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ss.ss_net_profit) AS sales_amount
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_customer_sk IN (SELECT c.customer_sk FROM LowestIncomeCustomers c)
    GROUP BY 
        c.c_customer_sk
) s
LEFT JOIN AddressInfo ca ON ca.ca_address_sk = (
    SELECT 
        c.c_current_addr_sk 
    FROM 
        customer c 
    WHERE 
        c.c_customer_sk = s.customer_id
)
WHERE 
    EXISTS (
        SELECT 1 
        FROM RankedSales rs 
        WHERE rs.item_sk = s.item_id AND rs.rnk = 1
    )
ORDER BY 
    sales_environment, state_rank;
