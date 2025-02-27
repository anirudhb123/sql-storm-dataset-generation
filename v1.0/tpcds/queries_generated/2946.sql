
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_qty) AS avg_return_qty
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (ORDER BY SUM(sr.total_return_amt) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
    HAVING 
        SUM(sr.total_return_amt) > 1000
),
ProductSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(cs.cs_order_number) AS promo_sales_count,
        SUM(cs.cs_net_paid) AS promo_total_sales,
        DENSE_RANK() OVER (ORDER BY COUNT(cs.cs_order_number) DESC) AS promo_rank
    FROM 
        promotion p
    LEFT JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cu.cd_gender,
    cu.cd_marital_status,
    ps.total_quantity_sold,
    ps.total_net_profit,
    pr.promo_name,
    pr.promo_total_sales
FROM 
    HighValueCustomers cu
JOIN 
    ProductSales ps ON cu.c_customer_sk = ps.ws_item_sk
JOIN 
    Promotions pr ON ps.ws_item_sk = pr.p_promo_sk
WHERE 
    cu.customer_rank <= 10 
    AND ps.sales_rank <= 5 
    AND pr.promo_rank <= 3
ORDER BY 
    cu.c_last_name, cu.c_first_name;
