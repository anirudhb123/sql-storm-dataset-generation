WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2023-12-31'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_name,
    co.order_count,
    co.total_spent,
    COALESCE(ss.total_supply_value, 0) AS total_supply_value,
    (SELECT COUNT(*) FROM RankedOrders ro WHERE ro.o_orderstatus = 'F') AS finished_orders,
    (SELECT COUNT(*) FROM RankedOrders ro WHERE ro.o_orderstatus = 'P') AS pending_orders,
    CONCAT('Customer ', c.c_name, ' has spent a total of ', COALESCE(ROUND(co.total_spent, 2), 0), ' with ', COALESCE(co.order_count, 0), ' orders.') AS customer_summary
FROM 
    customerOrders co
JOIN 
    customer c ON co.c_custkey = c.c_custkey
LEFT JOIN 
    SupplierSummary ss ON ss.total_supply_value > 10000
ORDER BY 
    co.total_spent DESC
FETCH FIRST 10 ROWS ONLY;
