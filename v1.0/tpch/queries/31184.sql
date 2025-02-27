
WITH RECURSIVE sales_data AS (
    SELECT
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY
        c.c_custkey
    UNION ALL
    SELECT
        sd.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        sales_data sd
    JOIN
        orders o ON sd.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate < DATE '1997-01-01'
    GROUP BY
        sd.c_custkey
),
ranked_sales AS (
    SELECT
        sd.c_custkey,
        sd.total_sales,
        DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        sales_data sd
)
SELECT
    p.p_name,
    SUM(ps.ps_availqty) AS total_available,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
    COALESCE(r.r_name, 'Unknown') AS region_name
FROM
    part p
LEFT JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
    )
GROUP BY
    p.p_name, r.r_name
HAVING
    SUM(ps.ps_availqty) > (
        SELECT AVG(total_available)
        FROM (
            SELECT SUM(ps.ps_availqty) AS total_available
            FROM part p
            JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
            GROUP BY p.p_partkey
        ) AS subquery
    )
ORDER BY
    total_available DESC
LIMIT 10;
