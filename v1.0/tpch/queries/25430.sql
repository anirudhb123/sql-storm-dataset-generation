WITH RankedSuppliers AS (
    SELECT s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)

SELECT r.r_name, COUNT(DISTINCT ns.n_nationkey) AS nation_count,
       STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM RankedSuppliers s
JOIN supplier sup ON s.s_name = sup.s_name
JOIN nation ns ON sup.s_nationkey = ns.n_nationkey
JOIN region r ON ns.n_regionkey = r.r_regionkey
WHERE s.rank <= 3
GROUP BY r.r_name
ORDER BY nation_count DESC;
