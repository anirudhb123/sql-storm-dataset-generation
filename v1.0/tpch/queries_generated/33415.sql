WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT ch.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_custkey = c.c_custkey
    WHERE c.c_acctbal > 0 AND ch.level < 3
),
TotalOrderAmounts AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
PartSupplierCounts AS (
    SELECT ps.ps_partkey, COUNT(*) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
RankedParts AS (
    SELECT p.*, 
           RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
)
SELECT
    ch.c_name,
    COALESCE(oa.total_spent, 0) AS total_spent,
    COALESCE(su.supp_count, 0) AS supplier_count,
    rp.p_name,
    rp.p_retailprice,
    ROW_NUMBER() OVER (PARTITION BY ch.level ORDER BY ch.c_acctbal DESC) AS customer_rank
FROM
    CustomerHierarchy ch
LEFT JOIN TotalOrderAmounts oa ON ch.c_custkey = oa.o_custkey
LEFT JOIN (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supp_count
    FROM partsupp ps
    JOIN HighValueSuppliers hv ON ps.ps_suppkey = hv.s_suppkey
    GROUP BY ps.ps_partkey
) su ON su.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
JOIN RankedParts rp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT hv.s_suppkey FROM HighValueSuppliers hv))
WHERE 
    rp.rank <= 5 AND
    rp.p_size IS NOT NULL
ORDER BY 
    ch.level, total_spent DESC;
