WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
        WHERE s2.s_nationkey = s.s_nationkey
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
),
PartConsumption AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity, COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY l.l_partkey
),
ExpensiveParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, pc.total_quantity, pc.total_orders
    FROM part p
    LEFT JOIN PartConsumption pc ON p.p_partkey = pc.l_partkey
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2
    )
),
SupplierPartDetails AS (
    SELECT s.s_name, p.p_name, p.p_retailprice, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN ExpensiveParts p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT s.s_name, COUNT(DISTINCT sp.p_name) AS part_count
    FROM SupplierPartDetails sp
    JOIN supplier s ON sp.s_name = s.s_name
    WHERE s.s_nationkey IS NOT NULL
    GROUP BY s.s_name
    HAVING COUNT(DISTINCT sp.p_name) > 1
),
RankedSuppliers AS (
    SELECT s.s_name, sp.part_count,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY sp.part_count DESC) AS rnk
    FROM FilteredSuppliers s
)
SELECT s.s_name, s.part_count
FROM RankedSuppliers s
WHERE s.rnk = 1
AND EXISTS (
    SELECT 1
    FROM nation n
    WHERE n.n_nationkey = (SELECT DISTINCT s_nationkey FROM supplier WHERE s_name = s.s_name)
      AND n.n_comment IS NOT NULL
)
ORDER BY s.part_count DESC, s.s_name;
