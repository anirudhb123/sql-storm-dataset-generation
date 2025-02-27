
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS sale_rank
    FROM 
        web_sales
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sale_rank <= 5
    GROUP BY 
        c.c_customer_sk
),
StoreReturnsStats AS (
    SELECT 
        sr.s_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns sr
    JOIN 
        store s ON sr.s_store_sk = s.s_store_sk
    GROUP BY 
        sr.s_store_sk
),
ItemStats AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_list_price) AS total_web_sales
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_sales,
    ss.total_returns,
    ss.total_return_amt,
    is.total_web_orders,
    is.total_web_sales,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High Value'
        WHEN cs.total_sales > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE(ss.total_returns, 0) AS return_count,
    COALESCE(is.total_web_orders, 0) AS web_order_count
FROM 
    CustomerStats cs
LEFT JOIN 
    StoreReturnsStats ss ON cs.c_customer_sk = ss.s_store_sk
LEFT JOIN 
    ItemStats is ON cs.c_customer_sk = is.i_item_sk
WHERE 
    cs.total_orders IS NOT NULL
ORDER BY 
    cs.total_sales DESC, cs.total_orders DESC
LIMIT 100;
