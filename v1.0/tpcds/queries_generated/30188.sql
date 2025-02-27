
WITH RECURSIVE MonthlySales AS (
    SELECT 
        d_month_seq,
        SUM(ss_net_paid) AS total_sales
    FROM 
        date_dim AS dd
    JOIN 
        store_sales AS ss ON dd.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d_month_seq
    UNION ALL
    SELECT 
        ms.d_month_seq,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        MonthlySales AS ms
    JOIN 
        web_sales AS ws ON ms.d_month_seq = EXTRACT(MONTH FROM ws.ws_sold_date_sk)
    GROUP BY 
        ms.d_month_seq
),
TotalSales AS (
    SELECT 
        d_year,
        SUM(total_sales) AS yearly_sales
    FROM 
        MonthlySales
    JOIN 
        date_dim ON MonthlySales.d_month_seq = date_dim.d_month_seq
    GROUP BY 
        d_year
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_paid) > 10000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS count_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status_desc
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    td.d_year,
    ts.yearly_sales,
    cd.marital_status_desc,
    cd.count_customers,
    cd.avg_purchase_estimate,
    tc.c_customer_id,
    tc.total_spent
FROM 
    TotalSales AS ts
JOIN 
    date_dim AS td ON ts.d_year = td.d_year
LEFT JOIN 
    CustomerDemographics AS cd ON td.d_year = cd.cd_marital_status
LEFT JOIN 
    TopCustomers AS tc ON tc.total_spent > 10000
ORDER BY 
    td.d_year, ts.yearly_sales DESC;
