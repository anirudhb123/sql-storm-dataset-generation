WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
), 
SupplierWithMaxCost AS (
    SELECT 
        ps.ps_suppkey,
        MAX(ps.ps_supplycost) AS MaxSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
), 
CustomerPreferableNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS CustRank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal IS NOT NULL
)

SELECT 
    s.s_name,
    p.p_name,
    p.p_mfgr,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
    n.r_name AS Region,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finalized'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown Status' 
    END AS OrderStatus,
    COUNT(DISTINCT c.c_custkey) AS DistinctCustomers
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND ps.ps_supplycost = (SELECT MaxSupplyCost FROM SupplierWithMaxCost swc WHERE swc.ps_suppkey = l.l_suppkey)
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerPreferableNation cpn ON o.o_custkey = cpn.c_custkey AND cpn.CustRank = 1
WHERE 
    l.l_shipdate >= DATE '2022-05-01'
    AND l.l_returnflag = 'N'
    AND n.r_regionkey IS NOT NULL
GROUP BY 
    s.s_name, p.p_name, p.p_mfgr, n.r_name, o.o_orderstatus
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    Revenue DESC
UNION 
SELECT 
    'Total Revenue' AS s_name,
    NULL AS p_name,
    NULL AS p_mfgr,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
    NULL AS Region,
    NULL AS OrderStatus,
    NULL AS DistinctCustomers
FROM 
    lineitem l
WHERE 
    l.l_shipdate >= DATE '2022-05-01'
    AND l.l_returnflag = 'N';
