
WITH sales_summary AS (
    SELECT 
        s_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        AVG(ss_net_paid) AS avg_net_paid
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY 
        s_store_sk
),
customer_info AS (
    SELECT 
        c_current_cdemo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        c_current_cdemo_sk, cd_gender, cd_marital_status
),
top_stores AS (
    SELECT 
        s_store_sk,
        RANK() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        sales_summary
    WHERE 
        total_sales > 10000
)
SELECT 
    s.s_store_id,
    COALESCE(c.cd_gender, 'Unknown') AS gender,
    st.total_sales,
    st.total_transactions,
    st.avg_net_paid,
    ci.customer_count
FROM 
    store s
LEFT JOIN 
    sales_summary st ON s.s_store_sk = st.s_store_sk
LEFT JOIN 
    customer_info ci ON ci.c_current_cdemo_sk IN (
        SELECT c_current_cdemo_sk 
        FROM customer 
        WHERE c_customer_sk IN (
            SELECT sr_customer_sk 
            FROM store_returns 
            WHERE sr_returned_date_sk = (
                SELECT MAX(sr_returned_date_sk) 
                FROM store_returns
                WHERE sr_returned_quantity > 0
            )
        )
    )
WHERE 
    s.s_store_sk IN (SELECT s_store_sk FROM top_stores WHERE rank <= 5)
ORDER BY 
    st.total_sales DESC, gender;
