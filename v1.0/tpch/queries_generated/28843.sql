WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, rs.depth + 1
    FROM partsupp ps
    JOIN RecursiveSupplier rs ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100.00 LIMIT 1) 
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    n.n_name, 
    r.r_name, 
    SUM(s.s_acctbal) AS total_acctbal, 
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count, 
    MAX(rs.depth) AS max_depth
FROM RecursiveSupplier rs
JOIN supplier s ON rs.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY n.n_name, r.r_name
ORDER BY total_acctbal DESC;
