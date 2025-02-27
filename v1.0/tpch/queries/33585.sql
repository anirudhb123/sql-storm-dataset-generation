WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 

    UNION ALL 

    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        depth + 1
    FROM partsupp ps
    JOIN SupplyChain sc ON ps.ps_suppkey = sc.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)

SELECT
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(o.o_orderdate) AS most_recent_order,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_size, ')', ' - $', ROUND(p.p_retailprice, 2)), ', ') AS products_list
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN part p ON l.l_partkey = p.p_partkey
WHERE o.o_orderstatus IN ('O', 'F')
AND l.l_discount > 0
AND l.l_returnflag IS NULL
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_revenue DESC
LIMIT 50;
