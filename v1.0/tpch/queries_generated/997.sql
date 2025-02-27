WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'P')
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    AVG(sp.avg_supply_cost) AS avg_cost_per_part,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN 
    lineitem lo ON sp.ps_partkey = lo.l_partkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    lo.l_shipdate >= '2023-01-01'
    AND (lo.l_returnflag = 'N' OR lo.l_returnflag IS NULL)
    AND n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_revenue DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
