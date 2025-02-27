
WITH SalesSummary AS (
    SELECT 
        s_store_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2458110 AND 2458117
    GROUP BY 
        s_store_sk
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), TopStores AS (
    SELECT 
        s_store_sk,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    si.s_store_sk,
    si.s_store_name,
    si.total_sales,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status
FROM 
    SalesSummary si
JOIN 
    store s ON si.s_store_sk = s.s_store_sk
JOIN 
    TopStores ts ON si.s_store_sk = ts.s_store_sk
JOIN 
    CustomerInfo ci ON si.s_store_sk = (SELECT ss_store_sk FROM store_sales WHERE ss_sales_price = si.total_sales LIMIT 1)
WHERE 
    ts.sales_rank <= 5
ORDER BY 
    si.total_sales DESC;
