
WITH RevenueStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS average_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
TopCustomers AS (
    SELECT 
        cs.ws_bill_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.hd_income_band_sk,
        rs.total_sales,
        rs.total_orders,
        rs.average_profit
    FROM 
        CustomerDemographics cs
    JOIN RevenueStats rs ON cs.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank <= 10
),
ItemReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(*) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_quantity) > 0
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.hd_income_band_sk,
    COALESCE(ir.total_returned, 0) AS total_items_returned,
    COALESCE(ir.return_count, 0) AS return_events,
    tc.total_sales,
    tc.total_orders,
    tc.average_profit,
    CASE 
        WHEN tc.hd_income_band_sk IS NOT NULL THEN 
            (SELECT ib_upper_bound FROM income_band WHERE ib_income_band_sk = tc.hd_income_band_sk)
        ELSE 
            NULL
    END AS upper_income_bound,
    CASE 
        WHEN tc.average_profit > 100 THEN 
            'High Profit'
        WHEN tc.average_profit IS NULL THEN 
            'No Profit Data'
        ELSE 
            'Low Profit'
    END AS profit_category
FROM 
    TopCustomers tc
LEFT JOIN ItemReturns ir ON tc.c_customer_sk = ir.sr_item_sk
WHERE 
    (tc.cd_gender IS NOT NULL OR tc.cd_marital_status IS NOT NULL)
ORDER BY 
    total_sales DESC
FETCH FIRST 20 ROWS ONLY;
