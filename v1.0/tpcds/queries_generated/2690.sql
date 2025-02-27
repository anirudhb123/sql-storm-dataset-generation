
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1990
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
CustomerIncome AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_band,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    a.web_name,
    a.total_sales,
    b.income_band,
    b.customer_count,
    (SELECT AVG(total_sales) FROM RankedSales) AS avg_sales,
    (SELECT MAX(total_sales) FROM RankedSales) AS max_sales
FROM 
    RankedSales a
LEFT JOIN 
    CustomerIncome b ON a.web_site_sk IN (
        SELECT 
            c_current_hdemo_sk 
        FROM 
            customer 
        WHERE 
            c_current_addr_sk IS NOT NULL
    )
WHERE 
    a.sales_rank <= 5
ORDER BY 
    a.total_sales DESC;
