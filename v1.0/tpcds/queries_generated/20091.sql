
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_item_sk,
        ss_ticket_number,
        ss_quantity,
        ss_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_ticket_number) AS rn
    FROM 
        store_sales
    WHERE 
        ss_quantity > 0
),
demographic_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Estimate Not Available' 
            ELSE CAST(cd.cd_purchase_estimate AS VARCHAR) 
        END AS purchase_estimation
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        sd.ss_item_sk,
        SUM(sd.ss_quantity) AS total_quantity,
        SUM(sd.ss_net_paid) AS total_sales
    FROM 
        sales_data sd
    GROUP BY 
        sd.ss_item_sk
),
joined_info AS (
    SELECT 
        ds.ss_item_sk,
        ds.total_quantity,
        ds.total_sales,
        di.c_customer_sk,
        di.c_first_name,
        di.c_last_name,
        di.marital_status,
        di.purchase_estimation
    FROM 
        sales_summary ds
    FULL OUTER JOIN 
        demographic_info di ON ds.ss_item_sk = (
            SELECT 
                i_item_sk 
            FROM 
                item 
            WHERE 
                i_item_id = (SELECT i_item_id FROM item ORDER BY RANDOM() LIMIT 1) 
            AND 
                i_rec_start_date <= CURRENT_DATE
            LIMIT 1
        )
)
SELECT 
    ji.c_customer_sk,
    ji.c_first_name,
    ji.c_last_name,
    ji.marital_status,
    ji.purchase_estimation,
    COALESCE(ji.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ji.total_sales, 0.00) AS total_sales_amt,
    CASE 
        WHEN ji.total_sales IS NULL THEN 'No Sales'
        WHEN ji.total_sales > 1000 THEN 'High Roller'
        ELSE 'Average Shopper' 
    END AS shopper_category
FROM 
    joined_info ji
WHERE 
    ji.total_sales IS NOT NULL 
    OR ji.marital_status <> 'Single'
ORDER BY 
    shopper_category DESC, ji.total_sales_amt DESC
FETCH FIRST 50 ROWS ONLY;
