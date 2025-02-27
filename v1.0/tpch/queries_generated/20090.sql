WITH RECURSIVE nation_info AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name, 
           COALESCE(s.s_acctbal, 0) AS total_acctbal
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE n.n_name IS NOT NULL
    UNION ALL
    SELECT ni.n_nationkey, ni.n_name, ni.r_regionkey, ni.r_name, 
           ni.total_acctbal + COALESCE(s.s_acctbal, 0)
    FROM nation_info ni
    JOIN supplier s ON ni.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000.00
    GROUP BY c.c_custkey, c.c_name
),
part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    WHERE l.l_returnflag = 'N'
    GROUP BY ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty
),
ranked_part AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand,
           p.p_retailprice, ps.total_revenue,
           RANK() OVER (PARTITION BY p.p_mfgr ORDER BY ps.total_revenue DESC) AS revenue_rank
    FROM part p
    LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size in (SELECT DISTINCT p_size FROM part WHERE p_container IS NULL)
),
final_results AS (
    SELECT ni.n_name, cs.c_name, rp.total_revenue, rp.revenue_rank,
           (CASE WHEN rp.total_revenue IS NULL THEN 'No Revenue' ELSE 'Revenue Available' END) AS revenue_status
    FROM nation_info ni
    JOIN customer_summary cs ON ni.total_acctbal > cs.total_spent
    LEFT JOIN ranked_part rp ON ni.n_nationkey = cs.c_custkey
)
SELECT r.n_name, r.c_name, 
       COALESCE(r.total_revenue, 0) AS final_revenue,
       r.revenue_rank, r.revenue_status
FROM final_results r
WHERE r.revenue_rank < 5 OR r.revenue_status = 'No Revenue'
ORDER BY r.n_name, r.c_name;
