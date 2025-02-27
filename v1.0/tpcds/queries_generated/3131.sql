
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        d.d_date,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
CustomerDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(c.c_customer_sk) AS total_customers
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_buy_potential
),
SalesSummary AS (
    SELECT 
        r.c_customer_id,
        r.d_date,
        SUM(r.ws_sales_price * r.ws_quantity) AS total_spent,
        COUNT(r.ws_quantity) AS total_orders
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
    GROUP BY 
        r.c_customer_id, r.d_date
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(ss.c_customer_id) AS customer_count,
    AVG(ss.total_spent) AS avg_spent,
    SUM(ss.total_orders) AS total_orders,
    CASE 
        WHEN COUNT(DISTINCT ss.c_customer_id) IS NULL THEN 'No Customers'
        ELSE 'Customers Present'
    END AS customer_presence
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesSummary ss ON cd.cd_demo_sk = ss.c_customer_id
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    AVG(ss.total_spent) DESC;
