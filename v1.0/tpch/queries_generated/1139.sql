WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -12, GETDATE())
), 

TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(*) AS ItemCount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
), 

SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplierCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(tc.TotalSales, 0) AS TotalSales,
    COALESCE(sc.TotalSupplierCost, 0) AS TotalSupplierCost,
    r.r_name AS Region,
    n.n_name AS Nation
FROM 
    part p
LEFT JOIN 
    TotalLineItems tc ON p.p_partkey = tc.l_orderkey
LEFT JOIN 
    SupplierCosts sc ON p.p_partkey = sc.ps_partkey
INNER JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
INNER JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
INNER JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 50.00
    AND NOT EXISTS (
        SELECT 1 
        FROM lineitem li 
        WHERE li.l_partkey = p.p_partkey 
          AND li.l_returnflag = 'Y'
    )
ORDER BY 
    TotalSales DESC, 
    p.p_partkey
FETCH FIRST 100 ROWS ONLY;
