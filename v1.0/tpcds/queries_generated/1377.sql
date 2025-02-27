
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_class,
        i_category
    FROM 
        item
    WHERE 
        i_current_price IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        cd_purchase_estimate
    FROM 
        customer 
        LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_purchase_estimate > 100
),
DateDetails AS (
    SELECT 
        d_date_sk,
        d_date,
        d_year
    FROM 
        date_dim
    WHERE 
        d_year IN (2021, 2022) AND d_holiday = 'Y'
),
RankedSales AS (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS rank
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM DateDetails)
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    id.i_item_desc,
    id.i_current_price,
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    SUM(ss.total_quantity) AS total_quantity_sold,
    SUM(ss.total_net_paid) AS total_net_paid,
    rs.total_profit,
    (CASE 
        WHEN cs.cd_credit_rating IS NULL THEN 'Unknown' 
        ELSE cs.cd_credit_rating 
    END) AS credit_rating,
    dt.d_date
FROM 
    SalesSummary ss
    JOIN ItemDetails id ON ss.ws_item_sk = id.i_item_sk
    JOIN CustomerDetails cs ON cs.c_customer_sk = (SELECT ws_ship_customer_sk FROM web_sales WHERE ws_item_sk = ss.ws_item_sk LIMIT 1)
    JOIN DateDetails dt ON dt.d_date_sk = ss.ws_sold_date_sk
    LEFT JOIN RankedSales rs ON id.i_item_sk = rs.ss_item_sk
GROUP BY 
    id.i_item_desc, 
    id.i_current_price, 
    cs.c_customer_sk, 
    cs.cd_gender, 
    cs.cd_marital_status, 
    rs.total_profit, 
    dt.d_date
HAVING 
    SUM(ss.total_net_paid) > 5000
ORDER BY 
    total_quantity_sold DESC, 
    total_net_paid DESC;
