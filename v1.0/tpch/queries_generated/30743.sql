WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_custkey = sh.c_custkey
    WHERE c.c_acctbal > sh.c_acctbal
),
part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
nation_region_summary AS (
    SELECT 
        n.n_regionkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey, n.n_name
),
orders_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
final_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ns.n_name AS supplier_nation,
        ps.total_available,
        ps.avg_supplycost,
        os.total_revenue,
        os.revenue_rank
    FROM part_summary ps
    LEFT JOIN nation_region_summary ns ON ps.total_available > 0
    LEFT JOIN orders_summary os ON ps.p_partkey = os.o_orderkey
)
SELECT 
    fs.p_partkey,
    fs.p_name,
    COALESCE(fs.supplier_nation, 'Unknown') AS supplier_nation,
    fs.total_available,
    fs.avg_supplycost,
    COALESCE(fs.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN fs.revenue_rank IS NULL THEN 'No Revenue'
        WHEN fs.revenue_rank <= 10 THEN 'Top Revenue'
        ELSE 'Other'
    END AS revenue_category
FROM final_summary fs
WHERE fs.total_available > 0
ORDER BY fs.total_revenue DESC, fs.p_partkey ASC;
