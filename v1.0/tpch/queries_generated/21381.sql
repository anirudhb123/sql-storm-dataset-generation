WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE ch.level < 5
),
UnlinkedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal < (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING COALESCE(SUM(ps.ps_supplycost), 0) > 100.00
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
           (CASE
                WHEN o.o_orderstatus = 'O' THEN 'Open Order'
                ELSE 'Closed Order'
            END) AS order_type
    FROM orders o
    WHERE o.o_totalprice > 1000.00 AND o.o_orderdate >= '2023-01-01'
),
SupplierRegion AS (
    SELECT s.s_suppkey, r.r_name,
           DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY r.r_name) AS region_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT DISTINCT ch.c_name, 
       (SELECT COUNT(DISTINCT l.l_orderkey) 
        FROM lineitem l 
        WHERE l.l_suppkey IN (SELECT ps.ps_suppkey 
                              FROM partsupp ps 
                              JOIN UnlinkedSuppliers us ON ps.ps_suppkey = us.s_suppkey)
       ) AS total_lineitems,
       COALESCE(MAX(sr.region_rank), 0) AS max_region_rank,
       AVG(ho.o_totalprice) AS avg_high_value_order
FROM CustomerHierarchy ch
LEFT JOIN SupplierRegion sr ON ch.c_custkey = sr.s_suppkey
LEFT JOIN HighValueOrders ho ON ho.o_orderkey IN (SELECT o.o_orderkey 
                                              FROM orders o 
                                              WHERE o.o_custkey = ch.c_custkey)
WHERE ch.level = 0
GROUP BY ch.c_name
HAVING SUM(ch.c_acctbal) > 5000.00 AND COUNT(sr.r_name) < 5
ORDER BY avg_high_value_order DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
