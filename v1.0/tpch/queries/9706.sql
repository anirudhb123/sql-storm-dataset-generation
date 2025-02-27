WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierRevenue AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sr.supplier_revenue
    FROM supplier s
    JOIN SupplierRevenue sr ON s.s_suppkey = sr.ps_suppkey
    ORDER BY sr.supplier_revenue DESC
    LIMIT 10
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    ts.s_name AS top_supplier_name,
    ts.supplier_revenue
FROM OrderSummary os
JOIN TopSuppliers ts ON OS.supplier_count = (SELECT COUNT(DISTINCT l.l_suppkey) FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
ORDER BY os.total_revenue DESC
LIMIT 20;
