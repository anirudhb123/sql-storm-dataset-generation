SELECT
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales_price,
    STRING_AGG(DISTINCT p.p_name, '; ') AS popular_parts,
    MAX(l.l_shipdate) AS latest_ship_date
FROM
    customer c
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    n.n_name LIKE '%USA%' AND
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY
    n.n_name
ORDER BY
    total_revenue DESC, customer_count DESC
LIMIT 10;