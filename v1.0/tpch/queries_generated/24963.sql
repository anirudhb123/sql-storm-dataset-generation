WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
CriticalParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 2
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CUME_DIST() OVER (ORDER BY o.o_totalprice DESC) as price_dist
    FROM orders o
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 100
),
SupplierOrderStats AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(COALESCE(cs.total_supply_cost, 0)) AS total_cost,
    SUM(CASE WHEN f.price_dist < 0.5 THEN 1 ELSE 0 END) AS low_price_orders,
    COUNT(DISTINCT so.l_suppkey) AS distinct_suppliers,
    MAX(so.total_revenue) AS max_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.supplier_rank <= 5
LEFT JOIN CriticalParts cs ON cs.p_partkey = rs.s_suppkey
LEFT JOIN FilteredOrders f ON f.o_orderkey = rs.s_suppkey
LEFT JOIN SupplierOrderStats so ON so.l_suppkey = rs.s_suppkey
WHERE rs.s_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(n.n_nationkey) > 1 AND MAX(so.avg_quantity) > (SELECT AVG(l.l_quantity) FROM lineitem l)
ORDER BY total_cost DESC, low_price_orders ASC;
