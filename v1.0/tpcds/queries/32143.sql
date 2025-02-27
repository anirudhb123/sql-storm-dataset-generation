
WITH RECURSIVE Sales_CTE AS (
    SELECT ss_item_sk, ss_quantity, ss_sales_price, ss_sold_date_sk, 1 AS level
    FROM store_sales 
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL
    
    SELECT ss.ss_item_sk, ss.ss_quantity + cte.ss_quantity, ss.ss_sales_price, ss.ss_sold_date_sk, level + 1
    FROM store_sales ss
    JOIN Sales_CTE cte ON ss.ss_item_sk = cte.ss_item_sk
    WHERE cte.level < 5
),
Customer_Data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
           COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
           COUNT(DISTINCT sr_ticket_number) AS total_store_returns
    FROM customer c 
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
High_Value_Customers AS (
    SELECT cd.*, 
           DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY total_web_sales DESC) AS sales_rank
    FROM Customer_Data cd
    WHERE total_web_sales > 1000
)
SELECT 
    hv.c_first_name,
    hv.c_last_name,
    hv.cd_gender,
    hv.total_web_sales,
    hv.total_store_returns,
    (SELECT AVG(total_web_sales) FROM Customer_Data) AS avg_web_sales,
    (SELECT COUNT(DISTINCT ss_item_sk) FROM store_sales ss WHERE ss.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)) AS total_items_sold,
    CASE 
        WHEN hv.total_web_sales > 5000 THEN 'Whale'
        WHEN hv.total_web_sales BETWEEN 1000 AND 5000 THEN 'Dolphin'
        ELSE 'Goldfish'
    END AS customer_value_label
FROM High_Value_Customers hv
WHERE hv.sales_rank <= 10
ORDER BY hv.total_web_sales DESC;

