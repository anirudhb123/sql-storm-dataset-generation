WITH RECURSIVE part_supplier AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        1 AS level
    FROM
        partsupp ps
    WHERE
        ps.ps_availqty > 0
    UNION ALL
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost * 0.9 AS ps_supplycost,
        level + 1
    FROM
        partsupp ps
    JOIN part_supplier ps_r ON ps.ps_partkey = ps_r.ps_partkey
    WHERE
        ps_r.ps_availqty < 100 AND level < 3
),
customer_order AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
nation_summary AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(c.c_acctbal) AS avg_acctbal
    FROM
        nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY
        n.n_nationkey
)
SELECT
    p.p_name,
    ps.ps_supplycost,
    ns.n_name,
    cs.total_spent,
    cs.order_count
FROM
    part p
LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN nation_summary ns ON ps.ps_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ns.n_nationkey LIMIT 1)
LEFT JOIN customer_order cs ON ns.n_nationkey = cs.c_custkey
WHERE
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 10
    )
    AND (cs.order_count > 5 OR cs.total_spent IS NULL)
ORDER BY
    p.p_name, cs.total_spent DESC
LIMIT 50;
