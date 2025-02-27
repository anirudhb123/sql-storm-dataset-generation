WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5 AND c.c_acctbal < (SELECT MAX(c3.c_acctbal) FROM customer c3 WHERE c3.c_nationkey = ch.c_nationkey)
),
PartSupplierStats AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
)
SELECT c.c_name, COALESCE(hv.total_revenue, 0) AS total_revenue, 
       COALESCE(ps.supplier_count, 0) AS supplier_count, 
       (CASE WHEN ps.avg_supply_cost IS NULL THEN 'No Suppliers' ELSE CAST(ps.avg_supply_cost AS VARCHAR) END) AS avg_supply_cost,
       c.level
FROM CustomerHierarchy c
LEFT JOIN (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
) hv ON c.c_custkey = hv.o_custkey
LEFT JOIN PartSupplierStats ps ON ps.p_partkey = (SELECT ps_partkey 
                                                     FROM partsupp 
                                                     WHERE ps_availqty = (SELECT MAX(ps_availqty) 
                                                                          FROM partsupp) 
                                                     LIMIT 1)
ORDER BY c.level, c.c_name
OPTION (RECOMPILE);
