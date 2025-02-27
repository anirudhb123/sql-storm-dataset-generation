WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_nationkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS TotalAvailable,
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS OutstandingSales,
    AVG(s.TotalSales) AS AvgSupplierSales,
    COUNT(DISTINCT p.p_partkey) AS UniqueParts,
    MAX(pd.TotalAvailable) AS MaxAvailable
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    RankedOrders o ON c.c_custkey = o.c_custkey AND o.OrderRank <= 5
LEFT JOIN 
    SupplierSales s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    )
LEFT JOIN 
    PartDetails pd ON pd.p_partkey IN (
        SELECT DISTINCT ps.ps_partkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_returnflag = 'R'
    )
WHERE 
    c.c_acctbal IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
