
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        co.total_quantity,
        co.total_revenue,
        ROW_NUMBER() OVER (ORDER BY co.total_revenue DESC) AS revenue_rank
    FROM 
        CustomerOrders co
    JOIN 
        customer_demographics cd ON co.c_customer_id = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
ReturnStatistics AS (
    SELECT 
        wr.refunded_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.refunded_customer_sk
),
FinalReport AS (
    SELECT 
        hvc.c_customer_id,
        hvc.total_quantity,
        hvc.total_revenue,
        rs.total_returns,
        rs.total_returned_amount
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        ReturnStatistics rs ON hvc.c_customer_id = rs.refunded_customer_sk
    WHERE 
        hvc.revenue_rank <= 100
)
SELECT 
    f.c_customer_id,
    f.total_quantity,
    f.total_revenue,
    COALESCE(f.total_returns, 0) AS total_returns,
    COALESCE(f.total_returned_amount, 0) AS total_returned_amount
FROM 
    FinalReport f
ORDER BY 
    f.total_revenue DESC;
