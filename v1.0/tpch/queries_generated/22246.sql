WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM 
        orders o
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        n.n_nationkey,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, n.n_nationkey
)
SELECT 
    p.p_name,
    MAX(rn.supplier_count) AS max_supplier_count,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    CASE WHEN AVG(rn.supplier_count) IS NULL THEN 'No Suppliers' ELSE 'Has Suppliers' END AS supplier_status,
    COALESCE(ROUND((SUM(li.l_extendedprice * (1 - li.l_discount)) - COALESCE(pt.total_supply_cost, 0)) / NULLIF(SUM(li.l_extendedprice), 0), 2), 2), 0) AS profit_margin,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ': ', rn.supplier_count) ORDER BY rn.supplier_count DESC) AS supplier_info
FROM 
    lineitem li
JOIN 
    RankedOrders ro ON li.l_orderkey = ro.o_orderkey
LEFT JOIN 
    PartSuppliers pt ON li.l_partkey = pt.ps_partkey
JOIN 
    RegionNation rn ON ro.o_orderdate IN (SELECT o_orderdate FROM orders WHERE o_orderkey = ro.o_orderkey)
JOIN 
    part p ON li.l_partkey = p.p_partkey
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT li.l_orderkey) > 5 AND 
    MAX(rn.supplier_count) > 10
ORDER BY 
    total_revenue DESC NULLS LAST;
