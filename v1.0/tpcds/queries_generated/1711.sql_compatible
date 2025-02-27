
WITH SalesData AS (
    SELECT 
        s_store_sk, 
        s_store_name,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        AVG(ss_net_profit) AS avg_net_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
    GROUP BY 
        s_store_sk, s_store_name
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT s.ss_ticket_number) AS transaction_count
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
), 
PopularItems AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity_sold
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
    HAVING 
        SUM(ss_quantity) > 100
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_purchase_estimate
    FROM 
        customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 50000
)
SELECT 
    sd.s_store_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sd.total_sales) AS total_store_sales,
    AVG(cd.transaction_count) AS avg_transactions_per_customer,
    COUNT(DISTINCT hic.c_customer_sk) AS high_value_customer_count,
    STRING_AGG(DISTINCT CONCAT('Item:', pi.ss_item_sk, ' Quantity Sold:', pi.total_quantity_sold)) AS popular_items
FROM 
    SalesData sd
LEFT JOIN CustomerDemographics cd ON sd.s_store_sk = cd.c_customer_sk 
LEFT JOIN PopularItems pi ON cd.transaction_count > 0
LEFT JOIN HighValueCustomers hic ON cd.c_customer_sk = hic.c_customer_sk
GROUP BY 
    sd.s_store_name, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_store_sales DESC;
