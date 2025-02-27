WITH String_Aggregation AS (
    SELECT
        p.p_partkey,
        p.p_name,
        STRING_AGG(s.s_name, ', ') AS supplier_names,
        STRING_AGG(DISTINCT CONCAT(n.n_name, ' (${n.n_nationkey})'), '; ') AS nations
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        p.p_partkey, p.p_name
),
Order_Summary AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY
        o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderpriority
),
Final_Report AS (
    SELECT
        a.p_partkey,
        a.p_name,
        a.supplier_names,
        a.nations,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.total_quantity,
        o.unique_customers
    FROM
        String_Aggregation a
    LEFT JOIN
        Order_Summary o ON a.p_partkey = (
            SELECT
                ps.ps_partkey
            FROM
                partsupp ps
            WHERE
                ps.ps_availqty > 0
            ORDER BY
                ps.ps_supplycost ASC
            LIMIT 1
        )
    ORDER BY
        o.o_totalprice DESC
)
SELECT
    *
FROM
    Final_Report
WHERE
    supplier_names LIKE '%Supplier%'
AND
    unique_customers > 1
ORDER BY
    p_partkey, o_orderdate DESC;
