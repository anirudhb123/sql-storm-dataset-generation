
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey
),
SelectedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
NationRegions AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(SUM(ro.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
    AVG(ss.total_supply_cost) AS avg_supply_cost
FROM 
    NationRegions n
LEFT JOIN 
    RankedOrders ro ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ro.o_orderkey)
LEFT JOIN 
    SelectedSuppliers ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#1'))
LEFT JOIN 
    region r ON n.r_regionkey = r.r_regionkey  -- Include region join for correct GROUP BY
GROUP BY 
    n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
HAVING 
    COUNT(ro.o_orderkey) > 0
ORDER BY 
    total_revenue DESC, supplier_count DESC;
