
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS Total_Net_Profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.web_site_sk, ws.web_site_id
),
TopSites AS (
    SELECT web_site_sk, web_site_id
    FROM RankedSales
    WHERE profit_rank <= 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_credit_rating IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
SalesSummary AS (
    SELECT
        ts.web_site_id,
        SUM(cd.total_spent) AS Female_Customers_Total_Spent,
        AVG(cd.total_orders) AS Avg_Orders_Per_Customer
    FROM TopSites ts 
    JOIN CustomerDetails cd ON cd.c_customer_sk = ts.web_site_sk
    GROUP BY ts.web_site_id
)
SELECT 
    ss.web_site_id,
    ss.Female_Customers_Total_Spent,
    ss.Avg_Orders_Per_Customer,
    COALESCE(inv.inv_quantity_on_hand, 0) AS available_inventory
FROM SalesSummary ss
LEFT JOIN inventory inv ON inv.inv_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_web_site_sk = ss.web_site_id)
ORDER BY ss.Female_Customers_Total_Spent DESC;
