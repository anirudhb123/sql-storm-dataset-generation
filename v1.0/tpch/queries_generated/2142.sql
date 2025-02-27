WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),

TotalOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),

CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_nationkey,
        r.r_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)

SELECT 
    cr.r_regionkey,
    cr.n_nationkey,
    ts.total_orders,
    ts.total_spent,
    ss.total_supplycost,
    CASE 
        WHEN ts.total_spent IS NULL THEN 'No Orders' 
        ELSE 'Orders Placed'
    END AS order_status
FROM CustomerRegion cr
LEFT JOIN TotalOrders ts ON cr.c_custkey = ts.o_custkey
LEFT JOIN RankedSuppliers ss ON cr.n_nationkey = ss.s_nationkey AND ss.rn = 1
WHERE (ts.total_orders > 5 OR ts.total_spent > 500.00)
  AND cr.n_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_comment LIKE '%important%')
ORDER BY cr.r_regionkey, ts.total_spent DESC;
