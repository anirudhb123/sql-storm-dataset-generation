
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS total_items_sold
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        h.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
RankedSales AS (
    SELECT 
        sd.ws_bill_customer_sk,
        sd.total_profit,
        sd.total_orders,
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        h.hd_income_band_sk,
        RANK() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
)

SELECT 
    r.cd_gender,
    r.cd_marital_status,
    COUNT(*) AS number_of_customers,
    AVG(r.total_profit) AS avg_profit,
    AVG(r.total_orders) AS avg_orders,
    COUNT(DISTINCT r.ws_bill_customer_sk) AS unique_customers
FROM 
    RankedSales r
WHERE 
    r.profit_rank <= 10
GROUP BY 
    r.cd_gender, 
    r.cd_marital_status
ORDER BY 
    r.cd_gender, 
    r.cd_marital_status;
