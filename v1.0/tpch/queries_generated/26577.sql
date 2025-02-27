WITH StringProcessing AS (
    SELECT
        p.p_partkey,
        p.p_name,
        s.s_name,
        n.n_name,
        (SELECT COUNT(*) FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)) AS order_count,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Nation: ', n.n_name) AS full_description,
        LENGTH(CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Nation: ', n.n_name)) AS description_length
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        LENGTH(p.p_name) > 10
        AND s.s_acctbal > 0
)
SELECT
    p_partkey,
    p_name,
    s_name,
    n_name,
    order_count,
    full_description,
    description_length
FROM
    StringProcessing
WHERE
    description_length BETWEEN 50 AND 100
ORDER BY
    description_length DESC;
