WITH RECURSIVE part_sales AS (
    SELECT
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        part p
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        p.p_partkey
),
high_value_parts AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
    HAVING
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
supplier_info AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(ps.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(ps.total_sales, 0) AS total_sales,
    s.s_name,
    s.nation_name
FROM
    part_sales ps
FULL OUTER JOIN high_value_parts hp ON ps.p_partkey = hp.ps_partkey
JOIN supplier_info s ON ps.p_partkey = ANY (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = s.s_suppkey)
WHERE
    (COALESCE(total_supply_cost, 0) > 5000 OR COALESCE(total_sales, 0) > 5000)
ORDER BY
    total_sales DESC,
    total_supply_cost DESC
LIMIT 10;
