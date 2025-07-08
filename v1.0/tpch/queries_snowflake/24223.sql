
WITH RECURSIVE HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN HighValueSuppliers hvs ON s.s_suppkey = hvs.s_suppkey
    WHERE s.s_acctbal > hvs.s_acctbal * 0.9
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 100
),
SignificantOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT r.r_name, n.n_name, s.s_name, pd.p_name,
       COALESCE(ss.total_avail_qty, 0) AS total_avail_qty,
       COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
       CASE WHEN hs.s_suppkey IS NOT NULL THEN 'High Value' ELSE 'Regular' END AS supplier_category
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN HighValueSuppliers hs ON s.s_suppkey = hs.s_suppkey
LEFT JOIN PartDetails pd ON s.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE 'Special%')
      AND ps.ps_supplycost < (
          SELECT AVG(ps2.ps_supplycost)
          FROM partsupp ps2
          WHERE ps2.ps_partkey = pd.p_partkey
      )
    LIMIT 1
)
LEFT JOIN SupplierStats ss ON pd.p_partkey = ss.ps_partkey
WHERE pd.price_rank <= 5
ORDER BY r.r_name, n.n_name, s.s_name;
