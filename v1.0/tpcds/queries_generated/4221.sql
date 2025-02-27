
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        DATE_DIM.d_year
    FROM 
        web_sales ws
    JOIN 
        date_dim DATE_DIM ON ws.ws_sold_date_sk = DATE_DIM.d_date_sk
    WHERE 
        DATE_DIM.d_year >= 2020
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
MonthSales AS (
    SELECT 
        DATE_DIM.d_year,
        DATE_DIM.d_moy,
        SUM(ws.ws_net_paid) AS monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim DATE_DIM ON ws.ws_sold_date_sk = DATE_DIM.d_date_sk
    GROUP BY 
        DATE_DIM.d_year, DATE_DIM.d_moy
)
SELECT 
    inv.inv_item_sk,
    COALESCE(RankedSales.price_rank, 'No Sales') AS sales_rank,
    COALESCE(high.comp_total_spent, 0) AS customer_spending,
    MONTHLY.d_year,
    MONTHLY.d_moy,
    MONTHLY.monthly_sales
FROM 
    inventory inv
LEFT JOIN 
    RankedSales ON inv.inv_item_sk = RankedSales.ws_item_sk
LEFT JOIN 
    (SELECT c.c_customer_sk, SUM(ws.ws_net_paid) AS comp_total_spent
     FROM HighValueCustomers c
     JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
     GROUP BY c.c_customer_sk) high ON inv.inv_item_sk = high.c_customer_sk
FULL OUTER JOIN 
    MonthSales MONTHLY ON RankedSales.d_year = MONTHLY.d_year AND MONTHLY.d_moy = MONTHLY.d_moy
WHERE 
    inv.inv_quantity_on_hand > 10
ORDER BY 
    inv.inv_item_sk, customer_spending DESC;
