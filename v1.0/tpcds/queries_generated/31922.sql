
WITH RECURSIVE TopSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_profit) > 1000
), 
DateRange AS (
    SELECT 
        d.d_date AS sales_date,
        d.d_week_seq,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
), 
StoreSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_store_sales
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        HD.hd_buy_potential,
        COUNT(ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk, HD.hd_buy_potential
), 
SalesSummary AS (
    SELECT 
        tr.sales_date,
        sd.total_store_sales,
        SUM(t.total_net_profit) AS total_profits
    FROM 
        DateRange tr
    LEFT JOIN 
        StoreSales sd ON sd.ss_store_sk IN (SELECT ss_store_sk FROM store)
    LEFT JOIN 
        TopSales t ON t.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_sold_date_sk = tr.d_date_sk)
    GROUP BY 
        tr.sales_date, sd.total_store_sales
)
SELECT 
    S.sales_date,
    S.total_store_sales,
    COALESCE(S.total_profits, 0) AS total_profits,
    COUNT(C.c_customer_sk) AS total_customers,
    COUNT(DISTINCT C.c_customer_sk) FILTER (WHERE C.cd_gender = 'F') AS female_customers,
    COUNT(DISTINCT C.c_customer_sk) FILTER (WHERE C.cd_gender = 'M') AS male_customers
FROM 
    SalesSummary S
JOIN 
    CustomerDetails C ON C.total_orders > 0
GROUP BY 
    S.sales_date, S.total_store_sales
ORDER BY 
    S.sales_date;
