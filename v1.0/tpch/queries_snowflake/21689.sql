
WITH RankedSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS acct_rank
    FROM supplier
    WHERE s_acctbal IS NOT NULL
),
TotalLineitems AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    WHERE l_shipdate < DATE '1998-10-01' - INTERVAL '1 year'
    GROUP BY l_orderkey
),
OutstandingOrders AS (
    SELECT 
        o_orderkey,
        o_orderstatus,
        o_totalprice
    FROM orders
    WHERE o_orderstatus = 'O'
),
SupplierRegion AS (
    SELECT 
        n.n_regionkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, n.n_name, r.r_name
)
SELECT 
    sr.region_name,
    sr.supplier_count,
    COALESCE(SUM(t.total_revenue), 0) AS total_income,
    COALESCE(MAX(rs.s_acctbal), 0) AS max_supplier_acctbal,
    COUNT(DISTINCT oo.o_orderkey) AS outstanding_orders
FROM SupplierRegion sr
LEFT JOIN TotalLineitems t ON sr.n_regionkey = 
    (SELECT n.n_regionkey FROM nation n 
     WHERE n.n_nationkey IN (
        SELECT DISTINCT s_nationkey FROM supplier
     ) LIMIT 1)
LEFT JOIN RankedSuppliers rs ON sr.n_regionkey = rs.s_suppkey
LEFT JOIN OutstandingOrders oo ON t.l_orderkey = oo.o_orderkey
GROUP BY sr.region_name, sr.supplier_count
HAVING COALESCE(SUM(t.total_revenue), 0) > (SELECT AVG(total_revenue) FROM TotalLineitems)
   OR sr.supplier_count IS NULL
ORDER BY sr.region_name DESC, outstanding_orders ASC
LIMIT 10 OFFSET (SELECT COUNT(*) FROM orders) / 1000
