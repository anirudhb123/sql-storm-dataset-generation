WITH RECURSIVE price_history AS (
    SELECT
        ps.partkey,
        ps.suppkey,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY ps.partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM
        partsupp ps
    WHERE
        ps.ps_supplycost IS NOT NULL
),
ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = o.o_orderstatus)
),
filtered_suppliers AS (
    SELECT
        s.s_suppkey,
        SUM(SUBSTRING(s.s_comment, 1, 10) IS NOT NULL) AS non_null_comments
    FROM
        supplier s
    GROUP BY
        s.s_suppkey
    HAVING
        SUM(s.s_acctbal) > 1000
),
order_count AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
final_query AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        ph.ps_supplycost,
        oc.total_orders,
        CASE WHEN oc.total_orders > 0 THEN 'Active' ELSE 'Inactive' END AS customer_status
    FROM
        part p
    LEFT JOIN
        price_history ph ON p.p_partkey = ph.partkey AND ph.rn = 1
    LEFT JOIN
        filtered_suppliers fs ON fs.s_suppkey = ph.suppkey
    LEFT JOIN
        order_count oc ON oc.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE LENGTH(c.c_name) > 5)
    WHERE
        (ph.ps_supplycost IS NULL OR (ph.ps_supplycost < 50 AND ph.ps_availqty > 5))
    ORDER BY
        p.p_partkey
)
SELECT * FROM final_query
WHERE customer_status = 'Active'
UNION ALL
SELECT *
FROM (
    SELECT
        p.p_partkey,
        p.p_name,
        CONCAT('Supplier:', COALESCE(ph.suppkey::varchar, 'None')) AS supplier_info,
        'End of inactive' AS customer_status
    FROM
        part p
    LEFT JOIN
        price_history ph ON p.p_partkey = ph.partkey
    WHERE
        ph.ps_supplycost IS NULL
) AS inactive_suppliers
ORDER BY p_partkey;
