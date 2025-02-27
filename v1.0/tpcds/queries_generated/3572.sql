
WITH RankedSales AS (
    SELECT 
        ss.sold_date_sk,
        ss.sold_time_sk,
        ss.item_sk,
        ss.customer_sk,
        ss.quantity,
        ss.net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss.customer_sk ORDER BY ss.net_paid DESC) AS rank
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk = (
            SELECT MAX(sd.sold_date_sk)
            FROM store_sales sd
            WHERE sd.sold_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_current_year = 'Y')
        )
        AND ss.net_paid > 0
),
TopCustomers AS (
    SELECT 
        rs.customer_sk,
        SUM(rs.net_paid) AS total_spent,
        COUNT(rs.item_sk) AS total_items,
        MAX(rs.rank) AS max_rank
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 10
    GROUP BY 
        rs.customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        tc.total_spent,
        tc.total_items
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TopCustomers tc ON c.c_customer_sk = tc.customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.total_spent,
    cd.total_items,
    CASE 
        WHEN cd.total_spent > 1000 THEN 'High Spender' 
        WHEN cd.total_spent BETWEEN 500 AND 1000 THEN 'Medium Spender' 
        ELSE 'Low Spender' 
    END AS spender_category
FROM 
    CustomerDetails cd
WHERE 
    cd.cd_gender IS NOT NULL
ORDER BY 
    cd.total_spent DESC
FETCH FIRST 20 ROWS ONLY;
