
WITH RECURSIVE SalesTrend AS (
    SELECT
        1 AS level,
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
    GROUP BY
        ws_bill_customer_sk

    UNION ALL

    SELECT 
        st.level + 1,
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        SalesTrend st ON ws_bill_customer_sk = st.ws_bill_customer_sk
    WHERE
        ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim) - 30
        AND st.level < 12
    GROUP BY
        ws_bill_customer_sk, st.level
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(st.total_profit, 0) AS profit,
        ROW_NUMBER() OVER (ORDER BY COALESCE(st.total_profit, 0) DESC) AS rn
    FROM
        customer c
    LEFT JOIN
        SalesTrend st ON c.c_customer_sk = st.ws_bill_customer_sk
)
SELECT 
    tc.full_name,
    tc.profit,
    COALESCE(cd.education_status, 'Unknown') AS education,
    ca.ca_city, 
    ca.ca_state,
    CASE 
        WHEN tc.profit = 0 THEN 'No Profit'
        WHEN tc.profit < 100 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = tc.c_customer_sk)
WHERE 
    tc.rn <= 10
ORDER BY 
    tc.profit DESC
FETCH FIRST 10 ROWS ONLY;
