WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate <= CURRENT_DATE - INTERVAL '30 days'
      AND c.c_acctbal IS NOT NULL 
      AND c.c_acctbal > 100
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT p.p_partkey) AS unique_parts,
           AVG(s.s_acctbal) AS avg_acct
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
    GROUP BY s.s_suppkey
),
OrderLineMetrics AS (
    SELECT l.l_orderkey,
           COUNT(DISTINCT l.l_partkey) AS part_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, r.c_mktsegment,
       COALESCE(ss.total_cost, 0) AS supplier_total_cost,
       olm.part_count, olm.total_revenue, olm.return_count
FROM RankedOrders o
LEFT JOIN SupplierStats ss ON ss.total_cost IS NOT NULL
LEFT JOIN OrderLineMetrics olm ON o.o_orderkey = olm.l_orderkey
WHERE o.rnk <= 3
  AND (olm.part_count > 5 OR olm.return_count = 0)
ORDER BY o.o_orderdate DESC, o.o_orderkey;
