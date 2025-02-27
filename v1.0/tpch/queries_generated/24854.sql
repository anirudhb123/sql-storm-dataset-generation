WITH RecursiveCTE AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_size, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name,
           SUM(s.s_acctbal) OVER (PARTITION BY n.n_nationkey) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_suppkey IS NOT NULL OR n.n_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'C%')
),
SelectedParts AS (
    SELECT r.r_name, p.p_name, ps.ps_supplycost, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY ps.ps_supplycost) AS rank_cost,
           COUNT(ps.ps_supplycost) OVER (PARTITION BY r.r_name) AS total_parts
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN region r ON r.r_regionkey = (SELECT DISTINCT n.n_regionkey
                                       FROM nation n
                                       WHERE EXISTS (SELECT 1 FROM supplier s WHERE s.s_nationkey = n.n_nationkey
                                                     AND s.s_acctbal > 0))
)
SELECT ns.n_name, sp.r_name, sp.p_name, sp.ps_supplycost, sp.ps_availqty,
       CASE WHEN sp.ps_supplycost IS NULL THEN 'No Cost Available'
            ELSE CASE WHEN sp.ps_supplycost <= (SELECT AVG(ps_supplycost) FROM partsupp) THEN 'Below Average'
                      ELSE 'Above Average' END
       END AS cost_category,
       CASE WHEN nullif(sp.total_parts, 0) IS NULL THEN 'No Parts' ELSE CAST(sp.total_parts AS VARCHAR) END AS part_count,
       SUM(sp.ps_supplycost * (1 - l.l_discount)) AS total_revenue
FROM SelectedParts sp
JOIN lineitem l ON l.l_partkey = sp.p_partkey
RIGHT JOIN NationSupplier ns ON ns.n_nationkey = l.l_suppkey
WHERE sp.rank_cost <= 5 AND ns.total_acctbal IS NOT NULL
GROUP BY ns.n_name, sp.r_name, sp.p_name, sp.ps_supplycost, sp.ps_availqty
HAVING SUM(sp.ps_supplycost * (1 - l.l_discount)) IS NOT NULL
ORDER BY ns.n_name, sp.r_name, total_revenue DESC;
