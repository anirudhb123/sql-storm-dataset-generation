WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_name LIKE 'A%'
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
), 
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, s.s_name, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), 
daily_order_summary AS (
    SELECT o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderdate
), 
high_revenue_days AS (
    SELECT oos.o_orderdate,
           oos.revenue, 
           DENSE_RANK() OVER (ORDER BY oos.revenue DESC) AS revenue_rank
    FROM daily_order_summary oos
    WHERE oos.revenue > 10000
    AND oos.o_orderdate >= DATE '2023-01-01'
)

SELECT psi.p_name, psi.s_name, psi.p_retailprice, nh.n_name AS supplier_nation,
       COALESCE(hd.revenue, 0) AS high_revenue, 
       hd.order_count || ' orders' AS order_stat,
       CASE 
           WHEN nh.level IS NULL THEN 'Unknown Nation'
           ELSE 'Known Nation Level: ' || nh.level 
           END AS nation_info
FROM part_supplier_info psi
LEFT JOIN nation_hierarchy nh ON psi.p_partkey = nh.n_nationkey
FULL OUTER JOIN high_revenue_days hd 
    ON hd.o_orderdate = CURRENT_DATE
WHERE psi.rn = 1
AND (nh.n_name IS NULL OR nh.level <= 3)
ORDER BY psi.p_retailprice DESC, hd.high_revenue ASC NULLS LAST;
