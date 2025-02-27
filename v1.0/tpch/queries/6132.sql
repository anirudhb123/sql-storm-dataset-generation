WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ro.o_orderkey,
        ro.o_totalprice
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = (
            SELECT 
                o.o_custkey 
            FROM 
                orders o 
            WHERE 
                o.o_orderkey = ro.o_orderkey
        )
),
SupplierParts AS (
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
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    sp.s_name,
    sp.TotalSupplyCost
FROM 
    CustomerOrders co
JOIN 
    SupplierParts sp ON co.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        JOIN 
            partsupp ps ON l.l_partkey = ps.ps_partkey
        WHERE 
            l.l_shipdate >= DATE '1996-05-01' 
            AND l.l_shipdate < DATE '1997-05-01'
    )
ORDER BY 
    co.o_totalprice DESC, 
    sp.TotalSupplyCost ASC
LIMIT 100;