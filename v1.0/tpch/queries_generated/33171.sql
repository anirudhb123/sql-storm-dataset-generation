WITH RECURSIVE TopSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ts.level + 1
    FROM supplier s
    JOIN TopSuppliers ts ON s.s_acctbal > ts.s_acctbal * 1.05
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
SupplierParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT r.r_name, n.n_name, 
       COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
       AVG(o.o_totalprice) AS avg_order_value,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       COUNT(DISTINCT ts.s_suppkey) AS top_supplier_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
JOIN SupplierParts sp ON l.l_partkey = sp.ps_partkey
WHERE o.o_orderstatus IN ('O', 'F')
  AND l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_sales DESC NULLS LAST;
