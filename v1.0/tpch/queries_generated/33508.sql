WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty, 
           AVG(l.l_discount) AS avg_discount, 
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(l.l_extendedprice) DESC) AS rank
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, ps.total_availqty, ps.avg_discount
    FROM PartStats ps
    JOIN part p ON p.p_partkey = ps.p_partkey
    WHERE ps.rank <= 10
),
NationsWithSuppliers AS (
    SELECT n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT
    t.p_name,
    t.total_availqty,
    t.avg_discount,
    COALESCE(ns.supplier_count, 0) AS supplier_count,
    rh.r_name,
    rh.r_comment
FROM TopParts t
LEFT JOIN NationsWithSuppliers ns ON t.total_availqty > 100 
LEFT JOIN region rh ON rh.r_regionkey = (
    SELECT n.n_regionkey 
    FROM nation n 
    WHERE n.n_nationkey = (
        SELECT DISTINCT s.s_nationkey 
        FROM supplier s 
        WHERE s.s_suppkey IN (
            SELECT sh.s_suppkey 
            FROM SupplierHierarchy sh
        )
    )
)
WHERE t.avg_discount IS NOT NULL AND t.avg_discount < 0.2
ORDER BY t.total_availqty DESC, t.avg_discount ASC;
