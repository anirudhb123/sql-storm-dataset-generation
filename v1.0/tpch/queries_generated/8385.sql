WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey,
        p.p_type,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalValue
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank <= 5
    GROUP BY 
        s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.s_name,
    r.TotalValue,
    o.TotalRevenue,
    o.o_orderdate
FROM 
    HighValueSuppliers r
JOIN 
    RecentOrders o ON r.s_suppkey = o.o_orderkey
WHERE 
    r.TotalValue > 100000
ORDER BY 
    r.TotalValue DESC, o.TotalRevenue DESC;
