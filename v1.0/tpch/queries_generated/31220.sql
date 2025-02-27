WITH RECURSIVE CTE_Supply AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        1 AS recursion_level
    FROM
        partsupp ps
    WHERE
        ps.ps_availqty > 0
    
    UNION ALL
    
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty - 10 * recursion_level,
        ps.ps_supplycost,
        recursion_level + 1
    FROM
        partsupp ps
    INNER JOIN CTE_Supply cte ON ps.ps_partkey = cte.ps_partkey
    WHERE
        cte.ps_availqty - 10 * recursion_level > 0
)
SELECT
    p.p_name,
    n.n_name AS nation_name,
    COUNT(s.s_suppkey) AS supplier_count,
    AVG(CASE 
        WHEN c.c_acctbal IS NULL THEN 0 
        ELSE c.c_acctbal 
    END) AS average_customer_balance,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
FROM
    part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN CTE_Supply cte ON ps.ps_partkey = cte.ps_partkey AND ps.ps_suppkey = cte.ps_suppkey
INNER JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
INNER JOIN customer c ON c.c_nationkey = n.n_nationkey
INNER JOIN orders o ON o.o_custkey = c.c_custkey
INNER JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE
    l.l_shipdate > '2022-01-01' AND 
    l.l_shipdate < '2023-01-01' AND
    s.s_acctbal > 0
GROUP BY
    p.p_name, n.n_name
HAVING
    COUNT(s.s_suppkey) > 1
ORDER BY
    total_sales DESC;
