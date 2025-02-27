WITH String_Benchmark AS (
    SELECT
        p.p_partkey,
        p.p_name,
        s.s_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS total_lines,
        STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', s.s_name, ')'), ', ') AS suppliers_from_nations,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
        MAX(l.l_shipdate) AS last_shipdate,
        SUBSTRING(p.p_comment, 1, 20) AS truncated_comment,
        (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c WHERE c.c_mktsegment = 'BUILDING') AS building_customers
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        p.p_partkey, p.p_name, s.s_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    *,
    CONCAT('Order ', o_orderkey, ': ', total_lines, ' lines, last shipped on ', last_shipdate) AS formatted_output
FROM 
    String_Benchmark
WHERE 
    total_returned_quantity > 0
ORDER BY 
    o_totalprice DESC, total_lines DESC;
