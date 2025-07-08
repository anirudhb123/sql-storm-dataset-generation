
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS GenderRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnStatistics AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesStatistics AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        ss.total_sold,
        ss.total_sales_amount
    FROM 
        item i
    LEFT JOIN 
        ReturnStatistics rs ON i.i_item_sk = rs.sr_item_sk
    LEFT JOIN 
        SalesStatistics ss ON i.i_item_sk = ss.ws_item_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    isales.i_item_desc,
    isales.total_sold,
    isales.total_sales_amount,
    isales.total_returned,
    isales.total_return_amount,
    CASE 
        WHEN isales.total_sales_amount IS NOT NULL AND isales.total_sales_amount > 0 
        THEN ROUND((isales.total_return_amount / isales.total_sales_amount) * 100, 2) 
        ELSE 0 
    END AS return_percentage,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    CustomerDetails cd
JOIN 
    ItemSales isales ON cd.c_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_first_name = cd.c_first_name AND c_last_name = cd.c_last_name LIMIT 1)
WHERE 
    cd.GenderRank <= 5
ORDER BY 
    return_percentage DESC;
