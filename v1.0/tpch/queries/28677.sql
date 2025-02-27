SELECT
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(CASE 
            WHEN c.c_mktsegment LIKE 'HOUSEHOLD%' THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE 0 
        END) AS avg_household_revenue,
    STRING_AGG(DISTINCT n.n_name, ', ') AS supplier_nations,
    MAX(o.o_orderpriority) AS highest_order_priority
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_name LIKE '%soft%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_name
HAVING
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY
    total_supply_cost DESC;