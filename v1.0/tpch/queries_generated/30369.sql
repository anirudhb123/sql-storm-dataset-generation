WITH RECURSIVE supplier_hierarchy AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM
        supplier s
    WHERE
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT
        sp.s_suppkey,
        sp.s_name,
        sp.s_nationkey,
        sh.level + 1
    FROM
        supplier_hierarchy sh
    JOIN
        partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN
        supplier sp ON ps.ps_suppkey = sp.s_suppkey
    WHERE
        sp.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT CONCAT(p.p_name, '(', p.p_size, ')'), ', ') AS parts_sold,
    COUNT(DISTINCT sh.s_suppkey) AS unique_suppliers
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem li ON o.o_orderkey = li.l_orderkey
JOIN
    part p ON li.l_partkey = p.p_partkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN
    supplier_hierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE
    o.o_orderstatus = 'F' 
    AND li.l_returnflag = 'N'
    AND (p.p_retailprice IS NOT NULL OR p.p_comment IS NULL)
GROUP BY
    n.n_name
HAVING
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY
    total_revenue DESC
LIMIT 10;
