
WITH RECURSIVE RevenuePerCustomer AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, total_sales
    FROM RevenuePerCustomer
    WHERE sales_rank <= 10
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_purchase_estimate, cd.cd_credit_rating,
           CASE 
               WHEN cd.cd_dep_count IS NULL THEN 'None' 
               ELSE CAST(cd.cd_dep_count AS VARCHAR(10)) 
           END AS dep_count,
           CASE 
               WHEN cd.cd_dep_employed_count IS NOT NULL 
                    AND cd.cd_dep_college_count IS NOT NULL 
               THEN CONCAT('Employed: ', cd.cd_dep_employed_count, ', College: ', cd.cd_dep_college_count)
               ELSE 'Not available' 
           END AS employment_status
    FROM customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT tc.*, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, 
       cd.dep_count, cd.employment_status
FROM TopCustomers tc
LEFT JOIN CustomerDemographics cd ON tc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN customer_address ca ON ca.ca_address_sk = (
    SELECT c_current_addr_sk 
    FROM customer 
    WHERE c_customer_sk = tc.c_customer_sk
)
LEFT JOIN store s ON s.s_store_sk = (
    SELECT ss_store_sk 
    FROM store_sales 
    WHERE ss_customer_sk = tc.c_customer_sk 
    ORDER BY ss_sold_date_sk DESC 
    LIMIT 1
)
ORDER BY tc.total_sales DESC;
