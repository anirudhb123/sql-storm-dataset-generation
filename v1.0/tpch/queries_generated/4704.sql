WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2024-01-01'
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS TotalOrders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS AvgNetPrice,
    COALESCE(cs.TotalSpent, 0) AS CustomerTotalSpent,
    su.TotalSupplyCost
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    CustomerStats cs ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
JOIN 
    SupplierDetails su ON l.l_suppkey = su.s_suppkey
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = l.l_orderkey) 
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND l.l_shipdate >= '2023-01-01'
    AND l.l_shipdate < '2024-01-01'
GROUP BY 
    p.p_name, cs.TotalSpent, su.TotalSupplyCost
HAVING 
    COUNT(*) > 5
ORDER BY 
    AvgNetPrice DESC, TotalOrders DESC;
