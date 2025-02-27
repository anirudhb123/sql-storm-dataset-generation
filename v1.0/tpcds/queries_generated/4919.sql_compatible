
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_paid) AS average_transaction_value,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
RankedSales AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_spent, 
        cs.total_transactions, 
        cs.average_transaction_value,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerSales cs
),
FilteredData AS (
    SELECT 
        cs.c_customer_id,
        d.cd_gender,
        d.cd_marital_status,
        d.ib_lower_bound,
        d.ib_upper_bound,
        rs.spending_rank
    FROM 
        RankedSales rs
    INNER JOIN 
        customer c ON c.c_customer_id = rs.c_customer_id
    INNER JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE 
        rs.total_spent > (
            SELECT AVG(total_spent) FROM RankedSales
        )
        AND d.cd_gender IS NOT NULL
),
FinalResults AS (
    SELECT 
        fd.*,
        CASE 
            WHEN fd.spending_rank <= 10 THEN 'Top 10 Customers'
            WHEN fd.spending_rank BETWEEN 11 AND 50 THEN 'Top 50 Customers'
            ELSE 'Other Customers' 
        END AS customer_segment
    FROM 
        FilteredData fd
)
SELECT 
    customer_segment,
    COUNT(c_customer_id) AS customer_count,
    AVG(ib_upper_bound - ib_lower_bound) AS avg_income_band_range
FROM 
    FinalResults
GROUP BY 
    customer_segment
ORDER BY 
    customer_segment;
