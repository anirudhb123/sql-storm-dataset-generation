WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartAggregates AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    p.p_name, 
    r.r_name AS region,
    fs.line_count,
    pa.total_available_qty,
    pa.avg_supply_cost,
    ss.s_name AS supplier_name,
    ss.s_acctbal
FROM 
    part p
JOIN 
    PartAggregates pa ON p.p_partkey = pa.ps_partkey
JOIN 
    RankedSuppliers ss ON pa.total_available_qty > ss.s_acctbal
LEFT JOIN 
    FilteredOrders fs ON fs.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN 
    nation n ON ss.s_suppkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ss.supp_rank <= 5
ORDER BY 
    pa.avg_supply_cost DESC, fs.o_totalprice DESC;
