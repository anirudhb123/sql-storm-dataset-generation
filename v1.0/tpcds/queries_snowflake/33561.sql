
WITH Monthly_Sales AS (
    SELECT
        d.d_year AS sales_year,
        d.d_month_seq AS month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
    UNION ALL
    SELECT
        ms.sales_year,
        ms.month_seq + 1,
        NULL
    FROM
        Monthly_Sales ms
    WHERE
        ms.month_seq + 1 <= 12
),
Monthly_Sales_Aggregated AS (
    SELECT
        sales_year,
        month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        Monthly_Sales ms
    JOIN web_sales ws ON ms.sales_year = (SELECT MAX(d_year) FROM date_dim) AND ms.month_seq + 1 <= 12
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE
        d.d_month_seq = ms.month_seq + 1
    GROUP BY
        sales_year, month_seq
),
Customer_Average AS (
    SELECT
        c.c_customer_sk,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
)
SELECT
    CONCAT('Year: ', ms.sales_year, ', Month: ', ms.month_seq) AS period,
    COALESCE(ms.total_sales, 0) AS total_sales,
    COALESCE(avg.avg_net_profit, 0) AS avg_customer_net_profit,
    CASE 
        WHEN COALESCE(ms.total_sales, 0) > 10000 THEN 'High Sales'
        WHEN COALESCE(ms.total_sales, 0) BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    (SELECT COUNT(DISTINCT c.c_customer_sk)
     FROM customer c 
     WHERE c.c_preferred_cust_flag = 'Y' 
     AND EXISTS (SELECT 1 FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk = c.c_customer_sk AND ws2.ws_ext_sales_price > 100)) AS high_value_customers
FROM
    Monthly_Sales_Aggregated ms
LEFT JOIN Customer_Average avg ON 1=1
GROUP BY 
    ms.sales_year, ms.month_seq, ms.total_sales, avg.avg_net_profit
ORDER BY
    ms.sales_year, ms.month_seq;
