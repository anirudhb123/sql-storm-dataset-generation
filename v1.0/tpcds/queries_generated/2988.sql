
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.web_site_sk
), 
TopSales AS (
    SELECT 
        rs.web_site_sk,
        rs.total_quantity,
        rs.total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_profit <= 3
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
), 
SalesAndCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        ts.total_quantity,
        ts.total_profit
    FROM 
        CustomerDetails cs
    JOIN 
        TopSales ts ON cs.total_quantity_sold > 10
    WHERE 
        cs.sales_rank <= 5
)
SELECT 
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.cd_gender,
    sa.cd_marital_status,
    COALESCE(sa.total_quantity, 0) AS quantity,
    COALESCE(sa.total_profit, 0) AS profit,
    sa.cd_purchase_estimate,
    CASE 
        WHEN sa.total_profit > 1000 THEN 'High Value' 
        WHEN sa.total_profit BETWEEN 500 AND 1000 THEN 'Moderate Value' 
        ELSE 'Low Value' 
    END AS customer_value
FROM 
    SalesAndCustomers sa
ORDER BY 
    sa.total_profit DESC, sa.c_last_name ASC;
