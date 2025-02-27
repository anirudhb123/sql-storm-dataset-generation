WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartsWithDiscount AS (
    SELECT p.p_partkey, p.p_name, (SUM(l.l_discount) / COUNT(l.l_discount)) AS avg_discount
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT cn.n_name AS nation_name, 
       c.c_name AS customer_name, 
       coalesce(cs.total_spent, 0) AS total_spent,
       ps.p_name AS part_name,
       pw.avg_discount AS avg_dis,
       sh.level AS supplier_level
FROM customer c
LEFT JOIN CustomerOrderSummary cs ON c.c_custkey = cs.c_custkey
LEFT JOIN nation cn ON c.c_nationkey = cn.n_nationkey
LEFT JOIN PartsWithDiscount pw ON pw.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 0
)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = c.c_nationkey
LEFT JOIN part p ON p.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps 
    WHERE ps.ps_supplycost = (
        SELECT MAX(ps2.ps_supplycost)
        FROM partsupp ps2
        WHERE ps2.ps_partkey = ps.ps_partkey
    )
)
WHERE (sh.s_suppkey IS NULL OR sh.level > 1)
ORDER BY cn.n_name, c.c_name;
