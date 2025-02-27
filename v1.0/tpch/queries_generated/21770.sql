WITH RECURSIVE complex_part AS (
    SELECT p_partkey, p_name, p_retailprice, 
           CASE WHEN p_size > 12 THEN 'Large' 
                WHEN p_size BETWEEN 6 AND 12 THEN 'Medium' 
                ELSE 'Small' END AS size_category
    FROM part
    WHERE p_container IS NOT NULL
),
nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
part_revenue AS (
    SELECT lp.l_partkey, SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue
    FROM lineitem lp
    GROUP BY lp.l_partkey
),
max_revenue_part AS (
    SELECT p.p_partkey, p.p_name, pr.total_revenue
    FROM complex_part p
    JOIN part_revenue pr ON p.p_partkey = pr.l_partkey
    WHERE pr.total_revenue = (SELECT MAX(total_revenue) FROM part_revenue)
),
supplier_nation_info AS (
    SELECT ns.n_nationkey, MAX(ns.s_acctbal) AS max_acctbal
    FROM nation_supplier ns
    WHERE ns.rn = 1
    GROUP BY ns.n_nationkey
)
SELECT np.n_name, mp.p_name, mp.total_revenue, 
       COALESCE(nsi.max_acctbal, 0) AS max_acctbal, 
       CASE WHEN mp.total_revenue > 10000 THEN 'High Revenue' 
            ELSE 'Low Revenue' END AS revenue_classification,
       COUNT(DISTINCT fo.o_orderkey) AS related_orders
FROM max_revenue_part mp
LEFT JOIN supplier_nation_info nsi ON mp.p_partkey = nsi.n_nationkey
JOIN nation np ON nsi.n_nationkey = np.n_nationkey
LEFT JOIN filtered_orders fo ON fo.o_orderkey IN (
    SELECT l_orderkey 
    FROM lineitem 
    WHERE l_partkey = mp.p_partkey
)
GROUP BY np.n_name, mp.p_name, mp.total_revenue, nsi.max_acctbal
HAVING COUNT(DISTINCT fo.o_orderkey) > 0
ORDER BY max_acctbal DESC, mp.total_revenue DESC;
