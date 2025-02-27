WITH RegionSummary AS (
    SELECT r.r_name AS region_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' 
      AND o.o_orderdate < DATE '1997-01-01'
      AND l.l_shipdate >= DATE '1996-01-01' 
      AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY r.r_name
),
CustomerSummary AS (
    SELECT c.c_nationkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01' 
      AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY c.c_nationkey
)
SELECT rs.region_name,
       cs.total_spent,
       cs.total_orders,
       COALESCE(rs.total_revenue, 0) AS total_revenue,
       (CASE WHEN COALESCE(cs.total_orders, 0) > 0 
             THEN COALESCE(rs.total_revenue, 0) / cs.total_orders 
             ELSE 0 END) AS avg_revenue_per_order
FROM RegionSummary rs
FULL OUTER JOIN CustomerSummary cs ON rs.region_name = (SELECT r_name FROM region r JOIN nation n ON r.r_regionkey = n.n_regionkey WHERE n.n_nationkey = cs.c_nationkey)
ORDER BY rs.region_name, cs.total_spent DESC;