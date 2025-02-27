WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 100
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty + c.c_acctbal, ps.ps_supplycost
    FROM SupplyChain sc
    JOIN supplier s ON s.s_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_nationkey = (SELECT n_nationkey FROM customer WHERE c_custkey = sc.s_suppkey)
    )
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN customer c ON c.c_nationkey = s.s_nationkey
    WHERE ps.ps_availqty + c.c_acctbal > 50
)
SELECT r.r_name, COUNT(DISTINCT sc.s_suppkey) AS supplier_count, SUM(sc.ps_supplycost) AS total_supplycost
FROM SupplyChain sc
JOIN nation n ON sc.s_suppkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY total_supplycost DESC;
