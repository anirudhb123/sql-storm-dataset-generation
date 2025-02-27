WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 0 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
PartSupplierStats AS (
    SELECT ps.ps_partkey,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RegionAggregation AS (
    SELECT r.r_regionkey,
           r.r_name,
           SUM(s.s_acctbal) AS total_supplier_balance,
           COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rh.c_name,
       p.p_name,
       ps.supplier_count,
       CASE
           WHEN ps.supplier_count IS NULL THEN 'NO SUPPLIERS'
           ELSE 'SUPPLIERS PRESENT'
       END AS supplier_status,
       COALESCE(SUM(CASE 
           WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
           ELSE 0 
       END), 0) AS total_returned_value,
       ROW_NUMBER() OVER (PARTITION BY rh.level ORDER BY rh.c_custkey) AS customer_rank,
       ra.total_supplier_balance
FROM lineitem l
JOIN PartSupplierStats ps ON l.l_partkey = ps.ps_partkey
JOIN CustomerHierarchy rh ON l.l_orderkey = rh.c_custkey
LEFT JOIN RegionAggregation ra ON rh.c_nationkey = ra.nation_count
WHERE l.l_shipdate BETWEEN '1995-01-01' AND '1996-01-01'
  AND l.l_discount BETWEEN 0.05 AND 0.15
  AND (l.l_returnflag IS NULL OR l.l_returnflag != 'N')
GROUP BY rh.c_name, p.p_name, ps.supplier_count, ra.total_supplier_balance
HAVING COUNT(DISTINCT l.l_orderkey) > 1
ORDER BY rh.level, p.p_name ASC, supplier_status DESC;
