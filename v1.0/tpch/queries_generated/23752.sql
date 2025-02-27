WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000.00

    UNION ALL

    SELECT ps.ps_partkey, s.s_name, s.s_acctbal, sc.level + 1
    FROM supplier_chain sc
    JOIN partsupp ps ON ps.ps_suppkey = sc.s_suppkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE sc.level < 5
)

SELECT 
    n.n_name,
    COUNT(DISTINCT cust.c_custkey) AS unique_customers,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS open_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(s_chain.s_acctbal) AS max_acctbal
FROM nation n
LEFT JOIN customer cust ON cust.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = cust.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN part p ON p.p_partkey = l.l_partkey
LEFT JOIN (
    SELECT supplier_chain.s_suppkey, SUM(supplier_chain.s_acctbal) AS s_acctbal
    FROM supplier_chain
    GROUP BY supplier_chain.s_suppkey
) s_chain ON s_chain.s_suppkey = o.o_custkey
WHERE n.n_nationkey IS NOT NULL
AND (o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31' OR o.o_orderdate IS NULL)
GROUP BY n.n_nationkey
HAVING COUNT(DISTINCT cust.c_custkey) > 0
ORDER BY unique_customers DESC
FETCH FIRST 10 ROWS ONLY;
