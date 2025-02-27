WITH RecentOrders AS (
    SELECT o_orderkey, o_custkey, o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rn
    FROM orders
    WHERE o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierStats AS (
    SELECT ps_suppkey, SUM(ps_supplycost) AS total_supplycost, COUNT(*) as total_parts
    FROM partsupp
    GROUP BY ps_suppkey
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ss.total_supplycost, ss.total_parts
    FROM supplier s
    JOIN SupplierStats ss ON s.s_suppkey = ss.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000 AND ss.total_supplycost > 5000
),
CustomerRank AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment,
           RANK() OVER (ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IS NOT NULL
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT DISTINCT r.r_name, np.n_name, hvs.s_name AS supplier_name,
                SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
                AVG(hvs.total_supplycost) AS avg_supplycost,
                MAX(cr.rank) AS customer_rank
FROM region r
JOIN nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN HighValueSuppliers hvs ON np.n_nationkey = hvs.s_suppkey
LEFT JOIN lineitem l ON hvs.s_suppkey = l.l_suppkey
LEFT JOIN RecentOrders ro ON ro.o_custkey = hvs.s_suppkey
LEFT JOIN CustomerRank cr ON cr.c_custkey = ro.o_custkey OR cr.c_mktsegment LIKE '%Retail%'
GROUP BY r.r_name, np.n_name, hvs.s_name
HAVING COUNT(DISTINCT l.l_orderkey) > 5 AND AVG(l.l_discount) < 0.1
ORDER BY 1, 2, 3;
