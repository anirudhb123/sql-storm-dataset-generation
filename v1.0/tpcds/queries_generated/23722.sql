
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        r.r_reason_id,
        r.r_reason_desc,
        COALESCE(rc.return_count, 0) AS return_count,
        SUM(total_sales) AS total_spent
    FROM 
        customer c
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT 
            sr_customer_sk, 
            COUNT(*) AS return_count 
         FROM 
            store_returns 
         GROUP BY 
            sr_customer_sk) rc ON c.c_customer_sk = rc.sr_customer_sk
    LEFT JOIN 
        reason r ON r.r_reason_sk = (SELECT 
                                        sr_reason_sk 
                                      FROM 
                                        store_returns 
                                      WHERE 
                                        sr_customer_sk = c.c_customer_sk 
                                      ORDER BY 
                                        sr_return_quantity DESC 
                                      LIMIT 1)
    WHERE 
        rs.sales_rank = 1
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, r.r_reason_id, r.r_reason_desc, rc.return_count
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.return_count,
    hvc.total_spent,
    CASE 
        WHEN hvc.total_spent > 1000 THEN 'Gold'
        WHEN hvc.total_spent > 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_category
FROM 
    HighValueCustomers hvc
WHERE 
    hvc.return_count IN (SELECT 
                            COUNT(*) 
                         FROM 
                            store_returns 
                         WHERE 
                            sr_customer_sk IS NOT NULL 
                         GROUP BY 
                            sr_customer_sk) 
    OR 
    hvc.cd_gender IS NULL
ORDER BY 
    hvc.total_spent DESC
LIMIT 100;
