WITH RECURSIVE precipitate AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, r.r_name, SUM(l.l_extendedprice) AS total_cost
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE l.l_discount BETWEEN 0.05 AND 0.15
    AND o.o_orderdate BETWEEN '1996-01-01' AND CURRENT_DATE
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT n.n_name, r.r_name,
       COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END), 0) AS returned_sales,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
       CASE WHEN SUM(total_cost) > 10000 THEN 'High' ELSE 'Low' END AS cost_category
FROM precipitate p
LEFT JOIN nation n ON p.n_nationkey = n.n_nationkey
LEFT JOIN region r ON p.r_name = r.r_name
LEFT JOIN partsupp ps ON ps.ps_partkey IN (SELECT p_partkey FROM part) 
LEFT JOIN lineitem l ON l.l_partkey = ps.ps_partkey
GROUP BY n.n_name, r.r_name
HAVING SUM(NULLIF(total_cost, 0)) IS NOT NULL
ORDER BY returned_sales DESC, rank
LIMIT (SELECT COUNT(DISTINCT r_name) FROM region) OVER ();
