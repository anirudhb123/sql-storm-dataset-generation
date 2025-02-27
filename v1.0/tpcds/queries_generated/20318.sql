
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
PromotionDetails AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
), 
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > 1000
), 
AggregatedReturns AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_return_quantity) AS total_returns,
        SUM(cs.cs_return_amount) AS total_return_amount
    FROM 
        catalog_returns cs
    GROUP BY 
        cs.cs_item_sk
    HAVING 
        SUM(cs.cs_return_quantity) > 0
),
FinalOutput AS (
    SELECT 
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        SUM(pd.total_revenue) AS total_promotion_revenue,
        COUNT(r.total_spent) AS high_value_customers_count,
        AVG(r.total_spent) AS average_spent,
        COALESCE(ar.total_returns, 0) AS total_returns,
        COALESCE(ar.total_return_amount, 0) AS total_return_amount
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        PromotionDetails pd ON rc.rank <= 10
    LEFT JOIN 
        HighValueCustomers r ON rc.c_customer_sk = r.c_customer_sk
    LEFT JOIN 
        AggregatedReturns ar ON rc.c_customer_sk = ar.cs_item_sk
    GROUP BY 
        rc.c_first_name, rc.c_last_name, rc.cd_gender
)
SELECT 
    *
FROM 
    FinalOutput
WHERE 
    (total_promotion_revenue IS NOT NULL OR total_returns > 0)
    AND cd_gender IN ('M', 'F')
ORDER BY 
    total_promotion_revenue DESC, high_value_customers_count;
