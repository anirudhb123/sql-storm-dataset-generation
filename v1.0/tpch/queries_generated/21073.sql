WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
        AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 50)
)
SELECT
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_open_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_discounted_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')'), '; ') AS top_suppliers
FROM
    nation n
LEFT JOIN
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey
WHERE
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'A%')
    AND l.l_returnflag IS NULL
GROUP BY 
    n.n_name
HAVING 
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) > 0
ORDER BY 
    total_customers DESC
LIMIT 10
ON CONFLICT (n.n_name) DO UPDATE SET 
    total_open_orders = EXCLUDED.total_open_orders + total_open_orders,
    avg_discounted_price = (EXCLUDED.avg_discounted_price + avg_discounted_price) / 2;
