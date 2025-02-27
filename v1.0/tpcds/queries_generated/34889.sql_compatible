
WITH RECURSIVE SalesTrends AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(cs_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
),
TopProfitableCustomers AS (
    SELECT 
        st.cs_bill_customer_sk,
        st.total_net_profit,
        st.total_orders
    FROM 
        SalesTrends st
    WHERE 
        st.profit_rank <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate >= 5000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 2000 AND 5000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ProductReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CustomerReturnStats AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        COALESCE(pr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(pr.total_returned_amount, 0) AS total_returned_amount
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        ProductReturns pr ON ci.c_customer_id = pr.wr_returning_customer_sk
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    cu.customer_value,
    st.total_net_profit,
    st.total_orders,
    cr.total_returned_quantity,
    cr.total_returned_amount
FROM 
    TopProfitableCustomers st
JOIN 
    CustomerReturnStats cr ON st.cs_bill_customer_sk = cr.c_customer_id
JOIN 
    CustomerInfo cu ON st.cs_bill_customer_sk = cu.c_customer_id
WHERE 
    cr.total_returned_quantity < 5
ORDER BY 
    st.total_net_profit DESC;
