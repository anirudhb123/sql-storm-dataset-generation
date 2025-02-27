WITH recursive cte_customer_orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(o.o_totalprice) > 1000
),
cte_part_supplier AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        MIN(ps.ps_supplycost) AS min_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),
filtered_parts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size BETWEEN 5 AND 20 THEN 'Medium'
            WHEN p.p_size > 20 THEN 'Large'
            ELSE 'Small'
        END AS size_category
    FROM
        part p
    WHERE
        p.p_retailprice IS NOT NULL
        AND p.p_comment NOT LIKE '%obsolete%'
),
supplier_nation AS (
    SELECT
        s.s_suppkey,
        n.n_name,
        COUNT(o.o_orderkey) AS order_count
    FROM
        supplier s
    LEFT JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN
        lineitem l ON s.s_suppkey = l.l_suppkey
    LEFT JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY
        s.s_suppkey, n.n_name
)
SELECT
    cte.c_custkey,
    cte.c_name,
    pp.p_name,
    pp.size_category,
    ps.total_available,
    sn.n_name AS supplier_nation,
    sn.order_count,
    ROW_NUMBER() OVER (PARTITION BY cte.c_custkey ORDER BY pp.p_retailprice DESC) AS rank
FROM
    cte_customer_orders cte
CROSS JOIN 
    filtered_parts pp
JOIN
    cte_part_supplier ps ON pp.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier_nation sn ON sn.order_count > 5
WHERE
    ps.total_available IS NOT NULL
    AND pp.p_retailprice > (SELECT AVG(p.p_retailprice) FROM part p WHERE p.p_retailprice IS NOT NULL)
ORDER BY
    cte.c_custkey, pp.p_retailprice DESC;
