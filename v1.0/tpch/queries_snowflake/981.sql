
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationSales AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT r.r_regionkey, r.r_name, COUNT(rs.s_suppkey) AS top_supplier_count
    FROM region r
    LEFT JOIN RankedSuppliers rs ON r.r_regionkey = rs.s_nationkey
    WHERE rs.rank <= 5
    GROUP BY r.r_regionkey, r.r_name
)
SELECT ns.n_nationkey, ns.n_name, ns.total_orders, ns.total_revenue, 
       COALESCE(ts.top_supplier_count, 0) AS top_supplier_count
FROM NationSales ns
LEFT JOIN TopSuppliers ts ON ns.n_nationkey = ts.r_regionkey
WHERE ns.total_revenue > 1000000 AND ns.total_orders > 50
ORDER BY ns.total_revenue DESC, ns.n_name ASC;
