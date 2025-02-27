WITH RecursiveSupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT ps.s_suppkey, s.s_name, s.s_acctbal, level + 1
    FROM partsupp ps
    JOIN RecursiveSupplierCTE s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty < 50
),
CustomerOrderTotals AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRank AS (
    SELECT n.n_nationkey, n.n_name, RANK() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS nation_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, l.l_partkey, 
           AVG(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY l.l_partkey) AS avg_price,
           MAX(l.l_tax) AS max_tax
    FROM lineitem l
)

SELECT 
    ps.p_partkey, 
    p.p_name, 
    COALESCE(total_spent, 0) AS total_spent,
    s.s_name AS supplier_name,
    CASE 
        WHEN nr.nation_rank IS NULL THEN 'Unranked' 
        ELSE 'Rank: ' || nr.nation_rank 
    END AS nation_rank,
    l.avg_price,
    l.max_tax
FROM part ps
LEFT JOIN partsupp psu ON ps.p_partkey = psu.ps_partkey
LEFT JOIN supplier s ON psu.ps_suppkey = s.s_suppkey
LEFT JOIN CustomerOrderTotals cot ON s.s_nationkey = cot.c_custkey
LEFT JOIN NationRank nr ON s.s_nationkey = nr.n_nationkey
LEFT JOIN LineItemAnalysis l ON l.l_partkey = ps.p_partkey
WHERE ps.p_retailprice BETWEEN 50 AND 500
  AND (s.s_acctbal IS NULL OR s.s_acctbal > 2000)
ORDER BY total_spent DESC, ps.p_partkey;
