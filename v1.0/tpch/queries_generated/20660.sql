WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        l.l_suppkey
), 
HighValueSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        COALESCE(ts.total_sales, 0) AS total_sales
    FROM 
        RankedSuppliers rs 
    LEFT JOIN 
        TotalSales ts ON rs.s_suppkey = ts.l_suppkey
    WHERE 
        rs.rank = 1
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    COALESCE(SUM(l.l_quantity * l.l_extendedprice), 0) AS total_quantity_sold,
    AVG(CASE WHEN c.c_mktsegment = 'BUILDING' THEN l.l_extendedprice ELSE NULL END) AS avg_building_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS regions_supplied
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    HighValueSuppliers hvs ON l.l_suppkey = hvs.s_suppkey
LEFT JOIN 
    nation n ON hvs.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_partkey, hvs.s_suppkey
HAVING 
    SUM(l.l_quantity) > CASE WHEN hvs.total_sales > 100000 THEN 500 ELSE 100 END
ORDER BY 
    p.p_retailprice DESC, total_quantity_sold DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
