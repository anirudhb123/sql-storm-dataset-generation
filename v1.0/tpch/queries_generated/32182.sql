WITH RECURSIVE SupplyCTE AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rnk
    FROM partsupp
),
HighVolumeOrders AS (
    SELECT o.o_orderkey, SUM(l.l_quantity) AS total_quantity, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_quantity) > 100
),
NationSupplier AS (
    SELECT n.n_name, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
RegionRevenue AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS total_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_name
)
SELECT r.r_name, rr.total_revenue,
       COALESCE(n.n_name, 'N/A') AS nation_name,
       s.s_name AS supplier_name, s.s_acctbal,
       h.total_quantity AS order_quantity
FROM RegionRevenue rr
LEFT JOIN NationSupplier n ON rr.total_revenue > 1000 AND n.rank = 1
LEFT JOIN SupplyCTE s ON s.rnk = 1
LEFT JOIN HighVolumeOrders h ON h.total_revenue > 5000
WHERE rr.total_revenue IS NOT NULL
ORDER BY rr.total_revenue DESC, s.s_acctbal DESC;
