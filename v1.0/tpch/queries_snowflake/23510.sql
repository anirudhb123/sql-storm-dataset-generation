
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank,
        CASE 
            WHEN o.o_totalprice BETWEEN 1000 AND 5000 THEN 'Medium'
            WHEN o.o_totalprice < 1000 THEN 'Low'
            ELSE 'High'
        END AS PriceCategory
    FROM 
        orders o
),
TotalPartSupp AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.r_name, 
    n.n_name, 
    s.s_name,
    ROUND(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END), 2) AS ReturnedSales,
    COALESCE(AVG(o.o_totalprice), 0) AS AvgOrderValue,
    COUNT(DISTINCT c.c_custkey) AS UniqueCustomers,
    LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS LargeParts
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    TotalPartSupp t ON p.p_partkey = t.ps_partkey
WHERE 
    r.r_name LIKE 'A%' 
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 500)
    AND (o.o_orderstatus IN ('O', 'F') OR o.o_orderdate > '1996-01-01')
GROUP BY 
    r.r_name, n.n_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 1000 
    AND COUNT(o.o_orderkey) > 5
ORDER BY 
    ReturnedSales DESC
LIMIT 50;
