
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        LISTAGG(DISTINCT CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state), '; ') WITHIN GROUP (ORDER BY ca.ca_street_number) AS address_list
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, c.c_salutation, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
FullDetail AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.address_list,
        d.d_date AS sales_date,
        d.d_month_seq,
        d.d_year,
        ws.ws_sales_price,
        ws.ws_net_profit
    FROM RankedCustomers rc
    LEFT JOIN web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    fd.full_name,
    fd.cd_gender,
    fd.cd_marital_status,
    fd.cd_education_status,
    fd.address_list,
    COUNT(fd.sales_date) AS total_sales,
    SUM(fd.ws_net_profit) AS total_profit,
    MIN(fd.sales_date) AS first_purchase_date,
    MAX(fd.sales_date) AS last_purchase_date,
    LISTAGG(DISTINCT CONCAT(fd.d_month_seq, '-', fd.d_year), ', ') WITHIN GROUP (ORDER BY fd.d_month_seq) AS purchase_months
FROM FullDetail fd
WHERE fd.ws_net_profit > 1000
GROUP BY fd.full_name, fd.cd_gender, fd.cd_marital_status, fd.cd_education_status, fd.address_list
ORDER BY total_profit DESC
LIMIT 100;
