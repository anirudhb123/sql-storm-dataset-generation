
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales,
        SUM(ss.ss_ext_tax) AS total_tax,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ss.ss_item_sk) AS unique_items
    FROM
        customer AS c
    JOIN
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN 2458246 AND 2458671 -- Example date range
    GROUP BY
        c.c_customer_id
),
TotalSales AS (
    SELECT
        SUM(total_quantity) AS grand_total_quantity,
        SUM(total_sales) AS grand_total_sales,
        SUM(total_tax) AS grand_total_tax,
        SUM(total_transactions) AS grand_total_transactions,
        SUM(unique_items) AS grand_unique_items
    FROM
        CustomerSales
),
Demographics AS (
    SELECT
        cd.gender,
        cd.marital_status,
        ISNULL(cd.education_status, 'Unknown') AS education_status,
        SUM(cs.total_sales) AS demographic_sales
    FROM
        CustomerSales cs
    JOIN
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY
        cd.gender, cd.marital_status, cd.education_status
)
SELECT
    d.gender,
    d.marital_status,
    d.education_status,
    d.demographic_sales,
    t.grand_total_quantity,
    t.grand_total_sales,
    t.grand_total_tax,
    t.grand_total_transactions,
    t.grand_unique_items
FROM
    Demographics d,
    TotalSales t
ORDER BY
    d.demographic_sales DESC
LIMIT 10;
