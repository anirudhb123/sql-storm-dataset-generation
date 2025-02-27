WITH RECURSIVE RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
),
AggregatedOrders AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS total_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
MaxRevenueByCustomer AS (
    SELECT o.o_custkey, MAX(a.total_revenue) AS max_revenue
    FROM orders o
    JOIN AggregatedOrders a ON o.o_orderkey = a.o_orderkey
    GROUP BY o.o_custkey
),
CustomerRegion AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name, r.r_name AS region_name,
           COALESCE(MIN(a.max_revenue), 0) AS max_revenue
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN MaxRevenueByCustomer a ON c.c_custkey = a.o_custkey
    GROUP BY c.c_custkey, c.c_name, n.n_name, r.r_name
)
SELECT r.region_name, AVG(cr.max_revenue) AS avg_revenue,
       COUNT(DISTINCT cr.c_custkey) AS customer_count
FROM CustomerRegion cr
JOIN region r ON cr.region_name = r.r_name
LEFT JOIN RankedSuppliers rs ON rs.rank <= 5 AND rs.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_brand = 'Brand#1'
    GROUP BY ps.ps_suppkey
)
WHERE cr.max_revenue IS NOT NULL OR cr.max_revenue = 0
GROUP BY r.region_name
ORDER BY avg_revenue DESC;
