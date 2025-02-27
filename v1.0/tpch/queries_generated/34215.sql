WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        CAST(NULL AS varchar(100)) AS parent_sup 
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    UNION ALL
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        sh.s_suppkey AS parent_sup
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
),
order_summary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
part_details AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        MAX(p.p_retailprice) AS max_price,
        MIN(p.p_retailprice) AS min_price,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(SUM(os.total_revenue), 0) AS total_revenue,
    COALESCE(MAX(pd.max_price), 0) AS max_part_price,
    COALESCE(MIN(pd.min_price), 0) AS min_part_price,
    COUNT(DISTINCT sup_h.s_suppkey) AS suppliers_count
FROM nation n
LEFT JOIN supplier_hierarchy sup_h ON n.n_nationkey = sup_h.s_nationkey
LEFT JOIN order_summary os ON sup_h.s_suppkey = os.o_orderkey
LEFT JOIN part_details pd ON os.o_orderkey = pd.p_partkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING total_revenue > 1000
ORDER BY total_revenue DESC
LIMIT 10;
