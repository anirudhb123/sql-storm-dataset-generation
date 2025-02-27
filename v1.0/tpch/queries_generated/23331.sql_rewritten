WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS depth
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 5
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1997-01-01'
), PartSupplierAvailability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), RecentShippedItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           CASE 
               WHEN l.l_returnflag = 'R' THEN 'Returned'
               ELSE 'Shipped'
           END AS shipment_status
    FROM lineitem l
    WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
), MergedData AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           COALESCE(sa.total_avail, 0) AS total_availability, 
           ro.o_orderkey, ro.o_totalprice, ro.o_orderdate, 
           si.l_quantity, si.shipment_status
    FROM part p
    LEFT JOIN PartSupplierAvailability sa ON p.p_partkey = sa.ps_partkey
    LEFT JOIN RankedOrders ro ON ro.o_orderdate BETWEEN '1997-01-01' AND cast('1998-10-01' as date)
    LEFT JOIN RecentShippedItems si ON si.l_partkey = p.p_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type LIKE '%metal%')
), FinalOutput AS (
    SELECT mh.*, 
           RANK() OVER (PARTITION BY mh.o_orderkey ORDER BY mh.o_totalprice DESC) AS price_rank,
           CASE 
               WHEN mh.total_availability = 0 THEN 'Unavailable'
               WHEN mh.l_quantity IS NULL THEN 'Pending'
               ELSE 'Available'
           END AS availability_status
    FROM MergedData mh
)
SELECT f.*, 
       CASE 
           WHEN LENGTH(f.p_name) % 2 = 0 THEN UPPER(f.p_name)
           ELSE LOWER(f.p_name)
       END AS modified_part_name
FROM FinalOutput f
WHERE f.price_rank = 1 AND f.availability_status <> 'Pending'
ORDER BY f.o_orderdate DESC, f.p_retailprice DESC
LIMIT 100
OFFSET 50;