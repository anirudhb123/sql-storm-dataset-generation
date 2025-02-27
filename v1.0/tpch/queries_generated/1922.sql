WITH SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
RegionSales AS (
    SELECT r.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY r.r_name
)
SELECT rs.r_name, rs.order_count, rs.total_revenue,
       COALESCE(cs.total_spent, 0) AS customer_spent_total,
       COALESCE(ss.total_cost, 0) AS supplier_total_cost,
       CASE 
           WHEN rs.total_revenue > 100000 THEN 'High Revenue'
           WHEN rs.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
           ELSE 'Low Revenue'
       END AS revenue_category
FROM RegionSales rs
LEFT JOIN CustomerOrders cs ON cs.c_custkey IN (SELECT c.c_custkey 
                                                FROM customer c 
                                                WHERE c.c_nationkey IN (SELECT n.n_nationkey 
                                                                        FROM nation n 
                                                                        WHERE n.n_regionkey = rs.r_name))
LEFT JOIN SupplierStats ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey 
                                                FROM partsupp ps 
                                                WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                        FROM part p 
                                                                        WHERE p.p_container = 'SET' 
                                                                        AND p.p_retailprice > 100)
                                            )
ORDER BY rs.total_revenue DESC, rs.r_name ASC;
