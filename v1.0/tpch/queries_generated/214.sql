WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate
),
TopSuppliers AS (
    SELECT s.s_nationkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    GROUP BY s.s_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty,
           CASE 
               WHEN ps.ps_supplycost IS NULL THEN 0
               ELSE ps.ps_supplycost
           END AS supplycost_effective
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
FinalReport AS (
    SELECT c.c_name, c.c_acctbal, o.o_orderkey, pd.p_name, pd.p_retailprice,
           COALESCE(si.s_name, 'Unknown Supplier') AS supplier_name,
           COALESCE(t.supplier_count, 0) AS total_suppliers
    FROM customer c
    LEFT JOIN CustomerOrders o ON c.c_custkey = o.o_custkey
    LEFT JOIN PartDetails pd ON o.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey = pd.p_partkey
    )
    LEFT JOIN SupplierInfo si ON si.s_suppkey = pd.p_partkey
    LEFT JOIN TopSuppliers t ON t.s_nationkey = c.c_nationkey
    WHERE o.o_totalprice > 1000.00
    ORDER BY c.c_acctbal DESC, o.o_orderdate DESC
)
SELECT *
FROM FinalReport
WHERE total_suppliers > 2
UNION ALL
SELECT DISTINCT ‘Additional Info’, NULL, NULL, NULL, NULL, NULL, NULL
FROM supplier
WHERE s_acctbal < (SELECT AVG(s_acctbal) FROM supplier s1 WHERE s1.s_acctbal IS NOT NULL);
