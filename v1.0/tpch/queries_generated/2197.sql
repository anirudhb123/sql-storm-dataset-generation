WITH TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        partsupp ps
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        ss.ps_suppkey, 
        ss.total_supplycost,
        ss.avg_acctbal,
        ss.parts_supplied
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_supplycost > (SELECT AVG(total_supplycost) FROM SupplierStats)
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(ts.total_price, 0) AS order_total_price,
    COALESCE(tps.total_supplycost, 0) AS supplier_cost,
    ns.n_name AS supplier_nation
FROM 
    orders o
LEFT JOIN 
    TotalSales ts ON o.o_orderkey = ts.l_orderkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN 
    TopSuppliers tps ON s.s_suppkey = tps.ps_suppkey
WHERE 
    o.o_orderstatus IN ('O', 'F')
    AND (ts.unique_parts IS NULL OR ts.unique_parts > 1)
ORDER BY 
    o.o_orderdate DESC, order_total_price DESC;
