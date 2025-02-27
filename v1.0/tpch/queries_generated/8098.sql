WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), HighCostSuppliers AS (
    SELECT r.r_regionkey, r.r_name, ns.n_name, rs.total_cost
    FROM RankedSuppliers rs
    JOIN nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    WHERE rs.total_cost > (SELECT AVG(total_cost) FROM RankedSuppliers)
), OrderStats AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, l.l_partkey, l.l_quantity, l.l_discount, l.l_tax
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND l.l_shipdate <= CURRENT_DATE
)
SELECT hs.r_name AS region, hs.n_name AS nation, COUNT(DISTINCT os.o_orderkey) AS order_count, 
       SUM(os.o_totalprice) AS total_revenue, SUM(ls.l_quantity) AS total_quantity,
       SUM(ls.l_extendedprice * (1 - ls.l_discount) * (1 + ls.l_tax)) AS total_sales
FROM HighCostSuppliers hs
JOIN OrderStats os ON hs.total_cost > (SELECT AVG(total_cost) FROM RankedSuppliers)
JOIN lineitem ls ON os.l_partkey = ls.l_partkey
GROUP BY hs.r_name, hs.n_name
ORDER BY total_revenue DESC;
