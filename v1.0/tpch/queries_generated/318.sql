WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplierCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS TotalSpent,
        COUNT(o.o_orderkey) AS TotalOrders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    cs.TotalSpent,
    cs.TotalOrders,
    ss.TotalSupplierCost,
    r.o_orderpriority
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerOrderDetails cs ON r.o_orderkey = (SELECT MAX(o1.o_orderkey) FROM orders o1 WHERE o1.o_custkey = cs.c_custkey)
LEFT JOIN 
    SupplierStats ss ON EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey = r.o_orderkey AND l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0))
WHERE 
    r.OrderRank = 1 AND 
    (cs.TotalSpent > 1000 OR cs.TotalOrders > 10)
ORDER BY 
    r.o_orderdate DESC, r.o_orderpriority;
