
WITH RECURSIVE SalesData AS (
    SELECT ws_item_sk, SUM(ws_ext_sales_price) AS total_sales, COUNT(ws_order_number) AS sales_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1000 AND 1200
    GROUP BY ws_item_sk
    UNION ALL
    SELECT s.ss_item_sk, SUM(s.ss_ext_sales_price), COUNT(s.ss_ticket_number)
    FROM store_sales s
    JOIN SalesData sd ON s.ss_item_sk = sd.ws_item_sk
    GROUP BY s.ss_item_sk
),
SalesSummary AS (
    SELECT item.i_item_id, item.i_item_desc, sd.total_sales, sd.sales_count,
           DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
    JOIN item ON sd.ws_item_sk = item.i_item_sk
    WHERE sd.total_sales IS NOT NULL
),
TopItems AS (
    SELECT i_item_id, i_item_desc, total_sales, sales_count
    FROM SalesSummary
    WHERE sales_rank <= 10
),
CustomerDetails AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address,
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalOutput AS (
    SELECT ti.i_item_id, ti.i_item_desc, ti.total_sales, ti.sales_count,
           COUNT(DISTINCT cd.c_customer_sk) AS number_of_customers
    FROM TopItems ti
    LEFT JOIN web_sales ws ON ti.i_item_id = ws.ws_item_sk
    LEFT JOIN CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY ti.i_item_id, ti.i_item_desc, ti.total_sales, ti.sales_count
)
SELECT foi.i_item_id, foi.i_item_desc, foi.total_sales, foi.sales_count,
       foi.number_of_customers,
       CASE 
           WHEN foi.number_of_customers > 100 THEN 'High Demand'
           WHEN foi.number_of_customers BETWEEN 50 AND 100 THEN 'Moderate Demand'
           ELSE 'Low Demand'
       END AS demand_category
FROM FinalOutput foi
WHERE foi.total_sales IS NOT NULL
ORDER BY foi.total_sales DESC;
