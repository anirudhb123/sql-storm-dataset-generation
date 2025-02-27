
WITH CTE_Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(ROUND(cd.cd_credit_rating::numeric), 0) AS adjusted_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchases,
        COUNT(*) OVER (PARTITION BY cd.cd_gender) AS total_in_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
CTE_Returns_Summary AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
CTE_Sales_Summary AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid_inc_tax) AS total_spending,
        COUNT(ss_ticket_number) AS total_purchases
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
),
Ranked_Customers AS (
    SELECT 
        c.customer_id,
        cs.total_spending,
        rt.total_returned_amt,
        cs.total_purchases,
        rt.return_count,
        sd.rank_by_purchases,
        sd.total_in_gender,
        CASE 
            WHEN cs.total_spending IS NULL THEN 'UNKNOWN'
            WHEN rt.returned_amt IS NULL THEN 'NO RETURNS'
            ELSE 'NORMAL'
        END AS return_status
    FROM 
        CTE_Customer_Summary sd
    LEFT JOIN 
        CTE_Sales_Summary cs ON cs.ss_customer_sk = sd.c_customer_sk
    LEFT JOIN 
        CTE_Returns_Summary rt ON rt.sr_returning_customer_sk = sd.c_customer_sk
)
SELECT 
    rc.customer_id,
    COALESCE(rc.total_spending, 0) AS total_spending,
    COALESCE(rc.total_returned_amt, 0) AS total_returned_amt,
    rc.total_purchases,
    rc.return_count,
    CASE 
        WHEN rc.return_count > 0 AND rc.total_spending > 1000 THEN 'HIGH RETURN CUSTOMER'
        WHEN rc.return_count = 0 AND rc.total_spending < 100 THEN 'LOW SPENDING CUSTOMER'
        WHEN rc.return_count > 2 AND rc.total_spending < 500 THEN 'RETURN HEAVILY'
        ELSE 'AVERAGE CUSTOMER'
    END AS customer_category,
    CASE 
        WHEN rc.rank_by_purchases = 1 THEN 'TOP SPENDER'
        ELSE 'NON-TOP SPENDER'
    END AS spender_classification
FROM 
    Ranked_Customers rc
WHERE 
    rc.return_status <> 'UNKNOWN'
ORDER BY 
    rc.total_spending DESC, rc.return_count ASC;

