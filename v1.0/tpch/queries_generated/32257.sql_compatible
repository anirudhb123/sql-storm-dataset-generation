
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
    WHERE c.c_acctbal > 10000
),
SupplierOrders AS (
    SELECT s.s_suppkey, s.s_name, SUM(o.o_totalprice) AS total_spent
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY s.s_suppkey, s.s_name
),
FilteredRegions AS (
    SELECT r.r_regionkey, r.r_name
    FROM region r
    WHERE r.r_name LIKE '%North%'
),
PartSizeStats AS (
    SELECT p.p_type, AVG(p.p_size) AS avg_size, COUNT(*) AS total_parts
    FROM part p
    WHERE p.p_retailprice > 50
    GROUP BY p.p_type
)
SELECT 
    c.c_name,
    so.s_name,
    ps.avg_size,
    ps.total_parts,
    COALESCE(so.total_spent, 0) AS total_spent,
    ROW_NUMBER() OVER (PARTITION BY ps.p_type ORDER BY ps.total_parts DESC) AS rank
FROM CustomerHierarchy c
FULL OUTER JOIN SupplierOrders so ON c.c_custkey = so.s_suppkey
JOIN PartSizeStats ps ON ps.p_type = (SELECT p.p_type FROM part p WHERE p.p_partkey = (SELECT MIN(p2.p_partkey) FROM part p2 WHERE p2.p_retailprice < 100))
WHERE EXISTS (SELECT 1 FROM FilteredRegions fr WHERE fr.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = c.c_custkey))
ORDER BY total_spent DESC, avg_size ASC;
