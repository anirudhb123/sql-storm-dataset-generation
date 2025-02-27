WITH RECURSIVE part_supplier_hierarchy AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        s.s_name,
        1 AS level
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        s2.s_name,
        level + 1
    FROM part_supplier_hierarchy psh
    JOIN partsupp ps ON psh.ps_suppkey = ps.ps_suppkey
    JOIN supplier s2 ON ps.ps_suppkey = s2.s_suppkey
    WHERE s2.s_acctbal IS NOT NULL AND s2.s_acctbal > 1000 AND level < 3
),
ranked_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal < (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey IS NOT NULL)
),
filtered_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS num_line_items
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O') AND o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice
),
nation_summary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)

SELECT 
    psh.p_partkey,
    psh.p_name,
    n.n_name AS supplier_nation,
    rc.c_custkey,
    rc.c_name,
    f.o_orderkey,
    f.o_totalprice,
    n_summary.unique_suppliers,
    n_summary.total_acctbal,
    CASE 
        WHEN f.num_line_items IS NULL THEN 'No Items'
        ELSE
            CASE 
                WHEN f.num_line_items > 10 THEN 'Many Items'
                ELSE 'Few Items'
            END
    END AS item_description
FROM part_supplier_hierarchy psh
JOIN ranked_customers rc ON rc.rank <= 5
LEFT JOIN filtered_orders f ON f.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey = psh.p_partkey
)
JOIN nation_summary n_summary ON n_summary.unique_suppliers > 2
JOIN nation n ON n.n_nationkey = (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey = psh.ps_suppkey)
WHERE COALESCE(n.n_comment, 'No Comment') LIKE '%Quality%'
ORDER BY psh.p_name, rc.c_name, f.o_totalprice DESC;
