WITH RegionSupplier AS (
    SELECT r.r_regionkey, r.r_name, s.s_suppkey, s.s_acctbal, s.s_comment
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal IS NOT NULL OR s.s_comment IS NOT NULL
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
)
SELECT DISTINCT
    p.p_partkey,
    p.p_name,
    COALESCE(r.r_name, 'Unknown') AS region_name,
    COALESCE(rs.s_suppkey, -1) AS supplier_key,
    COALESCE(od.total_revenue, 0) AS total_revenue,
    p.p_retailprice * 1.2 AS retail_price_plus_margin,
    CASE
        WHEN ps.total_cost IS NOT NULL THEN ps.total_cost * 0.95
        ELSE 0
    END AS adjusted_cost,
    CASE
        WHEN rs.rank = 1 AND od.total_revenue > 50000 THEN 'High-Value Supplier'
        WHEN rs.rank >= 2 AND od.total_revenue > 10000 THEN 'Medium-Value Supplier'
        ELSE 'Low-Value Supplier'
    END AS supplier_value_category
FROM part p
LEFT JOIN RegionSupplier rs ON p.p_partkey = rs.s_suppkey
LEFT JOIN OrderDetails od ON p.p_partkey = od.o_orderkey
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN region r ON rs.r_regionkey = r.r_regionkey
WHERE (p.p_size BETWEEN 10 AND 25 OR p.p_type LIKE 'ECONOMY%')
  AND (rs.s_acctbal IS NULL OR rs.s_acctbal > 1000)
  AND p.p_comment IS NOT NULL
ORDER BY region_name DESC, total_revenue DESC NULLS LAST;
