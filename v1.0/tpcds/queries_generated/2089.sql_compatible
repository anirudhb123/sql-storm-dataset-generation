
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sale_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk, 
        ws_ship_customer_sk, 
        ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopProducts AS (
    SELECT 
        ss_item_sk,
        COUNT(*) AS return_count,
        SUM(ss_ext_sales_price) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        ss_item_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ss.total_quantity,
    ss.total_sales,
    ss.total_profit,
    tp.return_count,
    tp.total_returned
FROM 
    SalesSummary ss
JOIN 
    CustomerDetails cd ON cd.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    TopProducts tp ON tp.ss_item_sk = ss.ws_item_sk
WHERE 
    ss.sale_rank <= 5
    AND (tp.return_count IS NULL OR tp.return_count < 3)
ORDER BY 
    ss.total_sales DESC;
