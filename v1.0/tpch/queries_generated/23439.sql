WITH RECURSIVE SizeHierarchy AS (
    SELECT p_partkey, p_size, p_type
    FROM part
    WHERE p_size > 0
    UNION ALL
    SELECT p.p_partkey, p.p_size * 2, p.p_type
    FROM part p
    INNER JOIN SizeHierarchy sh ON p.p_partkey = sh.p_partkey
    WHERE sh.p_size < 100
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name
),
SupplierAvailability AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartSummary AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           MAX(p.ps_supplycost) AS max_supplycost,
           MIN(p.ps_supplycost) AS min_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(CASE 
                 WHEN l.l_returnflag = 'R' THEN l.l_quantity 
                 ELSE 0 
               END) AS total_returned
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr
)
SELECT c.c_name, 
       COALESCE(c.total_spent, 0) AS customer_total_spent,
       COALESCE(s.total_avail, 0) AS supply_avail,
       CASE 
           WHEN c.total_spent IS NULL THEN 'New Customer' 
           ELSE 'Regular Customer' 
       END AS customer_status,
       p.p_name, 
       p.max_supplycost, 
       p.min_supplycost, 
       p.supplier_count, 
       p.total_returned,
       SUM(ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.max_supplycost DESC)) 
          OVER () AS rank
FROM CustomerOrders c
FULL OUTER JOIN SupplierAvailability s ON c.c_custkey = s.s_suppkey
FULL OUTER JOIN PartSummary p ON c.c_custkey IS NULL AND p.p_partkey = s.s_suppkey
WHERE p.p_size IN (SELECT DISTINCT p_size FROM SizeHierarchy)
  AND (s.total_avail > 0 OR s.total_avail IS NULL)
ORDER BY c.c_name, p.p_name;
