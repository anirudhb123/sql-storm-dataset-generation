
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_ext_discount_amt
    FROM 
        web_sales
    WHERE 
        ws_order_number IN (SELECT DISTINCT ws_order_number FROM web_sales)
    UNION ALL
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_ext_sales_price,
        cs_ext_discount_amt
    FROM 
        catalog_sales
    WHERE 
        cs_order_number IN (SELECT DISTINCT cs_order_number FROM catalog_sales)
),
AggregatedSales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
CustomerDetails AS (
    SELECT DISTINCT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    SUM(asales.total_quantity) AS total_purchased_qty,
    SUM(asales.total_sales) AS total_revenue,
    COALESCE(ir.total_returns, 0) AS total_returns,
    (SUM(asales.total_sales) - COALESCE(ir.total_returns * i.i_current_price, 0)) AS net_revenue
FROM 
    CustomerDetails cd
JOIN 
    (SELECT * FROM AggregatedSales WHERE sales_rank = 1) asales ON cd.c_customer_sk = asales.ws_order_number
LEFT JOIN 
    ItemReturns ir ON asales.ws_item_sk = ir.sr_item_sk
JOIN 
    item i ON asales.ws_item_sk = i.i_item_sk
GROUP BY 
    cd.c_first_name, cd.c_last_name, cd.cd_gender
HAVING 
    net_revenue > 1000
ORDER BY 
    total_revenue DESC;
