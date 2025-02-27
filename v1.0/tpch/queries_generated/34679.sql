WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = s.s_nationkey)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey AND s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = s.n_nationkey)
)

SELECT
    p.p_partkey,
    p.p_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS order_rank,
    COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost,
    RANK() OVER (ORDER BY COALESCE(SUM(l.l_quantity), 0) DESC) AS quantity_rank
FROM
    part p
LEFT JOIN
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN
    supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
WHERE
    p.p_retailprice BETWEEN 50 AND 500
GROUP BY
    p.p_partkey, p.p_name
HAVING
    total_orders > 0 AND total_supply_cost IS NOT NULL
ORDER BY
    order_rank ASC, quantity_rank DESC;
