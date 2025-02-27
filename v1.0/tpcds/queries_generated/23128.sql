
WITH SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6)
    GROUP BY 
        ws.web_site_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics WHERE cd_marital_status = 'M')
),
InvStock AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
),
AllSales AS (
    SELECT 
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    cs.item_sk,
    cs.total_quantity,
    cs.total_sales,
    CASE 
        WHEN cs.total_quantity > ISNULL(stock.total_on_hand, 0) THEN 'Stock Shortage'
        ELSE 'Sufficient Stock'
    END AS stock_status,
    cust.c_first_name,
    cust.c_last_name,
    cust.cd_gender,
    cust.cd_marital_status
FROM 
    AllSales cs
LEFT JOIN 
    InvStock stock ON cs.item_sk = stock.inv_item_sk
JOIN 
    CustomerData cust ON cust.gender_rank <= 5
WHERE 
    cs.total_sales > (
        SELECT 
            AVG(total_sales) FROM AllSales
    )
ORDER BY 
    stock_status DESC,
    total_sales DESC;
