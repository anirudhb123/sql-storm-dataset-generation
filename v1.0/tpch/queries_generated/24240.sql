WITH RecursiveSupplierCTE AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS depth 
    FROM supplier 
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    UNION ALL 
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, r.depth + 1 
    FROM supplier s 
    JOIN RecursiveSupplierCTE r ON s.s_nationkey = r.s_nationkey 
    WHERE r.depth < 3 AND s.s_acctbal > r.s_acctbal
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, 
           CASE 
               WHEN p.p_size IS NULL THEN 'UNKNOWN' 
               ELSE CAST(p.p_size AS VARCHAR)     
           END AS part_size,
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn 
    FROM part p 
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_comment IS NOT NULL)
),
HighVolumeOrders AS (
    SELECT o.o_orderkey, SUM(l.l_quantity) AS total_quantity 
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    GROUP BY o.o_orderkey 
    HAVING SUM(l.l_quantity) > 100
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name 
    FROM nation n 
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey 
    WHERE r.r_name IS NOT NULL
)
SELECT 
    fp.part_size,
    n.n_name,
    SUM(ps.ps_availqty) AS total_availqty,
    AVG(ao.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    MAX(s.s_acctbal) AS max_acct_balance
FROM FilteredParts fp 
LEFT JOIN partsupp ps ON fp.p_partkey = ps.ps_partkey 
LEFT JOIN RecursiveSupplierCTE s ON ps.ps_suppkey = s.s_suppkey 
LEFT JOIN HighVolumeOrders ao ON ao.o_orderkey IN (
    SELECT l_orderkey FROM lineitem WHERE l_partkey = fp.p_partkey
) 
JOIN NationRegion n ON s.s_nationkey = n.n_nationkey 
WHERE fp.rn = 1 
AND (s.s_acctbal IS NOT NULL OR s.s_acctbal BETWEEN 1000 AND 5000) 
GROUP BY fp.part_size, n.n_name 
HAVING SUM(ps.ps_availqty) > 200 
ORDER BY avg_order_value DESC, total_availqty ASC 
LIMIT 10;
