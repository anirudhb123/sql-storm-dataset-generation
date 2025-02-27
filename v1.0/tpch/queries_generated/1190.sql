WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY si.total_supply_cost DESC) AS supplier_rank
    FROM supplier s
    JOIN SupplierInfo si ON s.s_suppkey = si.s_suppkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    c.c_name AS customer_name,
    ro.total_revenue,
    ts.s_name AS top_supplier
FROM RankedOrders ro
LEFT JOIN TopSuppliers ts ON ro.rn = 1
JOIN customer c ON ro.c_name = c.c_name
WHERE ro.total_revenue > (SELECT AVG(total_revenue) FROM RankedOrders)
ORDER BY o.o_orderdate DESC, ro.total_revenue DESC
LIMIT 100;
