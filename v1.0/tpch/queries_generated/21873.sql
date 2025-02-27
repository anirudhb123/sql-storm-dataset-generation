WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, NULL::integer AS parent_suppkey
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey AS parent_suppkey
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_acctbal < sh.s_acctbal
)
, cte_part AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
, nation_sales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN customer c ON c.c_nationkey = n.n_nationkey
    JOIN orders o ON o.o_custkey = c.c_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sum_lines.total_quantity, 0) AS total_quantity,
    COALESCE(supplier_summary.supplier_count, 0) AS supplier_count,
    CASE 
        WHEN ns.total_sales IS NOT NULL THEN ns.total_sales
        ELSE 0 
    END AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY supplier_summary.supplier_count DESC NULLS LAST) AS rank_by_supplier_count
FROM part p
LEFT JOIN (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_partkey
) sum_lines ON p.p_partkey = sum_lines.ps_partkey
LEFT JOIN (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
) supplier_summary ON p.p_partkey = supplier_summary.ps_partkey
LEFT JOIN nation_sales ns ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderdate IS NOT NULL)))
WHERE p.p_size < 100 AND (p.p_brand IS NOT NULL OR p.p_comment LIKE 'Obscure%')
ORDER BY supplier_count DESC, p.p_partkey ASC
LIMIT 100;
