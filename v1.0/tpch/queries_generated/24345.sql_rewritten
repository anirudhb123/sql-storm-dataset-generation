WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
),
nation_supplier AS (
    SELECT n.n_name, COUNT(DISTINCT sh.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
    GROUP BY n.n_name
),
avg_prices AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
top_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice = (
        SELECT MAX(p2.p_retailprice)
        FROM part p2
        WHERE p2.p_brand LIKE 'Brand#%'
    )
),
lineitem_summary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rev_rank
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY l.l_orderkey
),
revenue_by_nation AS (
    SELECT n.n_name, SUM(l.total_revenue) AS total_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem_summary l ON o.o_orderkey = l.l_orderkey
    GROUP BY n.n_name
)
SELECT n.n_name, 
       COALESCE(nb.supplier_count, 0) AS supplier_count,
       COALESCE(rb.total_revenue, 0) AS revenue,
       CASE 
           WHEN COALESCE(rb.total_revenue, 0) > 1000000 THEN 'High Revenue'
           ELSE 'Low Revenue'
       END AS revenue_category
FROM nation n
LEFT JOIN nation_supplier nb ON n.n_name = nb.n_name
LEFT JOIN revenue_by_nation rb ON n.n_name = rb.n_name
ORDER BY n.n_name ASC
FETCH FIRST 10 ROWS ONLY;