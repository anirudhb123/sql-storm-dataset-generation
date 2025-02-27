
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_mktsegment,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_mktsegment
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
PendingOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus,
           CASE 
              WHEN o.o_orderstatus IS NULL THEN 'UNKNOWN' 
              ELSE o.o_orderstatus 
           END AS order_status
    FROM orders o
    WHERE o.o_orderstatus LIKE 'P%'
),
MaxPartCosts AS (
    SELECT ps.ps_partkey, MAX(ps.ps_supplycost) AS max_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT DISTINCT 
    p.p_name, 
    COALESCE(rs.rn, 0) AS rank_in_region,
    fo.total_line_value,
    po.order_status,
    pc.max_cost
FROM part p
LEFT JOIN RankedSuppliers rs ON p.p_partkey = rs.s_suppkey
LEFT JOIN FilteredOrders fo ON p.p_partkey = fo.o_orderkey 
LEFT JOIN PendingOrders po ON fo.o_orderkey = po.o_orderkey
LEFT JOIN MaxPartCosts pc ON p.p_partkey = pc.ps_partkey
WHERE (p.p_size > 10 OR p.p_retailprice IS NOT NULL)
  AND (p.p_mfgr LIKE 'M%' OR p.p_container IN ('SM CASE', 'MED BOX'))
  AND (p.p_comment NOT LIKE '%back%' OR p.p_comment IS NULL)
ORDER BY p.p_name, rank_in_region DESC, fo.total_line_value ASC;
