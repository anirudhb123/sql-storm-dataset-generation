WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
        WHERE s2.s_nationkey IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), 
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps 
    WHERE ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, COUNT(DISTINCT li.l_orderkey) AS item_count
    FROM orders o
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_totalprice > 10000
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING COUNT(DISTINCT li.l_orderkey) > 3
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.total_avail_qty) AS total_availability,
           RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.total_avail_qty) DESC) AS availability_rank
    FROM part p
    JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT rh.supp_name, rh.supp_acctbal, 
       COALESCE(AVG(hvo.o_totalprice), 0) AS avg_order_value,
       rp.p_name,
       CASE 
           WHEN rp.availability_rank < 3 THEN 'HIGH' 
           WHEN rp.availability_rank IS NULL THEN 'UNKNOWN' 
           ELSE 'LOW' 
       END AS availability_category
FROM SupplierHierarchy rh
LEFT JOIN HighValueOrders hvo ON rh.s_suppkey = hvo.o_orderkey
LEFT JOIN RankedParts rp ON rp.p_partkey = (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey = rh.s_suppkey 
    ORDER BY ps.ps_availqty DESC 
    LIMIT 1
)
WHERE rh.level < 4
ORDER BY rh.supp_name, rp.availability_category DESC, avg_order_value DESC;
