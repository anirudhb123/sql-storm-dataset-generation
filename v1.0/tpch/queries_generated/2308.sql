WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderstatus
),
AggregatedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    np.n_name AS nation_name,
    COUNT(DISTINCT cu.c_custkey) AS customer_count,
    SUM(CASE WHEN fo.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS fulfilled_orders,
    SUM(ap.avg_supplycost) AS total_avg_supplycost
FROM region r
JOIN nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN customer cu ON np.n_nationkey = cu.c_nationkey
LEFT JOIN FilteredOrders fo ON cu.c_custkey = fo.o_custkey
JOIN AggregatedParts ap ON fo.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey IN (SELECT p_partkey FROM RankedSuppliers WHERE rn = 1))
WHERE cu.c_acctbal IS NOT NULL AND ap.num_suppliers > 5
GROUP BY r.r_name, np.n_name
ORDER BY total_avg_supplycost DESC, customer_count DESC;
