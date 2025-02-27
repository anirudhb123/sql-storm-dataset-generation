WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        s.s_acctbal > 1000.00
),
TotalOrderValue AS (
    SELECT
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_custkey
),
NationCounts AS (
    SELECT
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_nationkey
)
SELECT
    c.c_custkey,
    c.c_name,
    COALESCE(t.total_value, 0) AS total_order_value,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier,
    nc.supplier_count
FROM
    customer c
LEFT JOIN
    TotalOrderValue t ON c.c_custkey = t.o_custkey
LEFT JOIN
    RankedSuppliers rs ON rs.rank = 1 AND rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
LEFT JOIN
    NationCounts nc ON c.c_nationkey = nc.n_nationkey
WHERE
    (t.total_value IS NOT NULL OR nc.supplier_count > 0) 
    AND (c.c_acctbal IS NOT NULL OR c.c_name LIKE '%Inc%')
ORDER BY
    total_order_value DESC, c.c_custkey ASC;
