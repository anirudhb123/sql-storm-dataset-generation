WITH StringedData AS (
    SELECT
        p.p_name,
        r.r_name AS region,
        n.n_name AS nation,
        s.s_name AS supplier,
        c.c_name AS customer,
        o.o_orderkey,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name) AS detail_info,
        LENGTH(CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name)) AS info_length
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
)
SELECT
    region,
    COUNT(*) AS total_entries,
    MIN(info_length) AS min_length,
    MAX(info_length) AS max_length,
    AVG(info_length) AS avg_length,
    STRING_AGG(detail_info, '; ') AS concatenated_info
FROM
    StringedData
GROUP BY
    region
ORDER BY
    region;
