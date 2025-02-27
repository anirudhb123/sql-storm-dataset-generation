WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COALESCE(MAX(s.s_acctbal), 0) AS max_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
    FROM partsupp ps
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
FilteredLineitems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        MIN(l.l_shipdate) AS earliest_shipdate
    FROM lineitem l
    WHERE l.l_discount > 0.1
    GROUP BY l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    s.total_avail_qty,
    sol.o_orderkey,
    COUNT(DISTINCT p.p_container) AS unique_containers,
    CASE 
        WHEN COUNT(s.s_nationkey) IS NULL THEN 'No Supplier'
        ELSE 'Supplier Exists'
    END AS supplier_existence,
    COALESCE((SELECT AVG(r.r_regionkey) FROM region r), NULL) AS avg_regionkey,
    SUM(rol.net_revenue) AS total_revenue,
    MAX(rol.earliest_shipdate) AS most_recent_shipdate
FROM part p
LEFT JOIN SupplierPartDetails s ON p.p_partkey = s.ps_partkey
LEFT JOIN RankedOrders sol ON sol.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = sol.o_orderkey AND o.o_orderstatus = 'O' LIMIT 1)
LEFT JOIN FilteredLineitems rol ON rol.l_orderkey = sol.o_orderkey
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    s.total_avail_qty, 
    sol.o_orderkey
HAVING 
    SUM(s.total_supply_cost) > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps) 
    OR EXISTS (SELECT 1 FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')))
ORDER BY 
    p.p_name ASC, 
    total_revenue DESC
LIMIT 50 OFFSET 10;
