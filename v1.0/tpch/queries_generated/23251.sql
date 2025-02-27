WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_retailprice, p_comment, 
           NULL AS parent_partkey, 0 AS level
    FROM part
    WHERE p_size = (SELECT MAX(p_size) FROM part)

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_retailprice, p.p_comment, 
           ph.p_partkey AS parent_partkey, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_size < ph.p_size
),
SupplierAvailability AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_avail_qty, 
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, 
           o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerRegions AS (
    SELECT c.c_custkey, 
           n.n_regionkey,
           (SELECT COUNT(*) FROM nation) AS total_nations
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE n.n_regionkey IS NOT NULL
)
SELECT ph.p_partkey, ph.p_name, ph.p_brand, ph.p_retailprice, sa.total_avail_qty, 
       hv.total_order_value, cr.n_regionkey
FROM PartHierarchy ph
LEFT JOIN SupplierAvailability sa ON ph.p_partkey = sa.ps_partkey
JOIN HighValueOrders hv ON hv.o_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 5000
)
FULL OUTER JOIN CustomerRegions cr ON cr.c_custkey = hv.o_custkey
WHERE ph.level <= 5 AND 
      (sa.total_avail_qty IS NOT NULL OR cr.total_nations > 1)
ORDER BY ph.p_partkey, sa.total_avail_qty DESC NULLS LAST;
