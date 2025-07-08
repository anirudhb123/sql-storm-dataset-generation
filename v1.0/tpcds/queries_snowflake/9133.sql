
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS average_spent,
        COUNT(ws.ws_order_number) AS purchase_count,
        cd.cd_gender,
        CAST(d.d_date AS DATE) AS purchase_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE EXTRACT(YEAR FROM d.d_date) = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, d.d_date
), RankedPurchases AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY purchase_date ORDER BY total_spent DESC) AS rank
    FROM CustomerPurchases
)
SELECT 
    rp.purchase_date,
    LISTAGG(CONCAT(rp.c_first_name, ' ', rp.c_last_name, ': ', rp.total_spent), ', ') WITHIN GROUP (ORDER BY rp.total_spent DESC) AS top_customers,
    AVG(rp.average_spent) AS average_spent_per_customer,
    COUNT(*) AS total_customers
FROM RankedPurchases rp
WHERE rp.rank <= 5
GROUP BY rp.purchase_date
ORDER BY rp.purchase_date;
