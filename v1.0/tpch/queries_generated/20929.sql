WITH RegionalSales AS (
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY r.r_regionkey, r.r_name
),
CustomerStatus AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           CASE WHEN SUM(o.o_totalprice) IS NULL THEN 'Inactive'
                ELSE CASE WHEN SUM(o.o_totalprice) > 10000 THEN 'High Value'
                          ELSE 'Regular' END END AS customer_status
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_suppkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
FilteredSales AS (
    SELECT r.r_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           COALESCE(SUM(cs.order_count), 0) AS customer_orders
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN CustomerStatus cs ON c.c_custkey = cs.c_custkey
    GROUP BY r.r_name
)
SELECT rs.r_name, rs.total_revenue, fs.total_orders, fs.customer_orders
FROM RegionalSales rs
FULL OUTER JOIN FilteredSales fs ON rs.r_name = fs.r_name
WHERE (rs.total_revenue IS NOT NULL OR fs.total_orders IS NOT NULL)
ORDER BY COALESCE(rs.total_revenue, 0) DESC, COALESCE(fs.total_orders, 0) DESC
LIMIT 10;

SELECT DISTINCT p.p_name, s.s_name, COALESCE(t.total_cost, 0) AS total_supply_cost
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN TopSuppliers t ON s.s_suppkey = t.ps_suppkey 
WHERE p.p_size >= 10 AND (s.s_acctbal IS NULL OR s.s_acctbal BETWEEN 100 AND 500)
  AND NOT EXISTS (SELECT 1 FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_discount > 0.20)
ORDER BY total_supply_cost DESC
FETCH FIRST 5 ROWS ONLY;
