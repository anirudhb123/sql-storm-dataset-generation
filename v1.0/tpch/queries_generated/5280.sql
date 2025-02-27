WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplyRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
),
PartSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    hvc.c_custkey,
    hvc.c_name,
    ps.p_partkey,
    ps.p_name,
    ps.s_name,
    ps.ps_availqty,
    ps.ps_supplycost,
    rs.TotalSupplyCost,
    rs.SupplyRank
FROM 
    HighValueCustomers hvc
JOIN 
    PartSuppliers ps ON ps.ps_availqty > 50
JOIN 
    RankedSuppliers rs ON ps.p_partkey = rs.s_suppkey
WHERE 
    rs.SupplyRank = 1
ORDER BY 
    hvc.TotalSpent DESC, rs.TotalSupplyCost DESC;
