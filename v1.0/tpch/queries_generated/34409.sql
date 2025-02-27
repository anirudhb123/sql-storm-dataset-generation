WITH RECURSIVE Supp_CTE AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.level + 1
    FROM supplier s
    JOIN Supp_CTE sc ON s.s_suppkey = sc.s_suppkey
    WHERE s.s_acctbal BETWEEN 10000 AND 50000 AND sc.level < 3
),
Part_Supp AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           s.s_name AS supplier_name, p.p_name AS part_name, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
Max_Part AS (
    SELECT pm.part_name, MAX(pm.ps_supplycost) AS max_supplycost
    FROM Part_Supp pm
    GROUP BY pm.part_name
)
SELECT DISTINCT
    c.c_name,
    r.r_name,
    pp.part_name,
    pp.ps_supplycost,
    pp.ps_availqty,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN c.c_acctbal IS NULL THEN 'No Balance' 
        ELSE c.c_acctbal::TEXT 
    END AS customer_balance,
    COALESCE(MIN(l.l_shipdate), '0001-01-01') AS earliest_shipdate
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN region r ON c.c_nationkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = c.c_nationkey)
LEFT JOIN Part_Supp pp ON l.l_partkey = pp.ps_partkey
LEFT JOIN Max_Part mp ON pp.part_name = mp.part_name
WHERE pp.ps_supplycost = mp.max_supplycost
  AND l.l_returnflag = 'N'
GROUP BY c.c_name, r.r_name, pp.part_name, pp.ps_supplycost, pp.ps_availqty
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_price DESC, c.c_name;
