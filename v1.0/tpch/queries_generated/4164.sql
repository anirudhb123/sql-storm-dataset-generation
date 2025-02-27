WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn_status
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_nationkey
), NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_name) AS rn_nation
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_name,
    np.r_name AS nation_region,
    COALESCE(SUM(lp.l_extendedprice * (1 - lp.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_totalprice) AS max_order_value,
    COUNT(DISTINCT CASE WHEN lp.l_returnflag = 'R' THEN lp.l_orderkey END) AS returned_orders
FROM part p
LEFT JOIN lineitem lp ON p.p_partkey = lp.l_partkey
LEFT JOIN RankedOrders o ON lp.l_orderkey = o.o_orderkey
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN NationRegion np ON sp.s_nationkey = np.n_nationkey
WHERE p.p_retailprice > 50.00 
AND (np.n_name LIKE 'A%' OR np.n_name IS NULL)
GROUP BY p.p_partkey, np.r_name
HAVING COUNT(o.o_orderkey) > 5
ORDER BY total_revenue DESC, order_count DESC;
